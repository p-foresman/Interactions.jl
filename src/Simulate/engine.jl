
############################### FUNCTIONS #######################################

#state is only mutated within the scope of this function (using multiple dispatch for to optimize main simulation loop)
function simulate!(state::Types.State, ::Nothing, ::Nothing; stopping_condition_reached::Function)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::Types.State, timeout::Int, ::Nothing; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Types.timedout!(state)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::Types.State, ::Nothing, db_push_period::Int; stopping_condition_reached::Function)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        elseif iszero(period(state) % db_push_period)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::Types.State, timeout::Int, db_push_period::Int; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Types.timedout!(state)
            break
        elseif iszero(period(state) % db_push_period)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end



######################## game algorithm ####################
function run_period!(state::Types.State)
    for component in Types.components(state) #each connected component plays its own period's worth of matches
        # mpp = matches_per_period(num_vertices(component)) * edge_density(num_vertices(component), λ(graph_parameters(model))) #NOTE: CHANGE THIS BACK
        # for _ in 1:Int(ceil(mpp))
        for _ in 1:Types.matches_per_period(component)
            Types.reset_arrays!(state)
            Types.set_players!(state, component)
            play_game!(state)
        end
    end
    Types.increment_period!(state)
    return nothing
end



function play_game!(state::Types.State)
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.
    find_opponent_strategy_probabilities!(state)
    calculate_expected_utilities!(state)
    make_choices!(state)
    push_memories!(state)
    return nothing
end

function find_opponent_strategy_probabilities!(state::Types.State)
    for player_number in 1:2 #NOTE: only functional for 2 players!
        calculate_opponent_strategy_probabilities!(state, player_number)
    end
    return nothing
end


#other player isn't even needed without tags. this could be simplified
function calculate_opponent_strategy_probabilities!(state::Types.State, player_number::Integer)
    @inbounds for memory in Types.memory(Types.players(state, player_number))
        Types.increment_opponent_strategy_recollection!(state, player_number, memory) #memory strategy is simply the payoff_matrix index for the given dimension
    end
    Types.opponent_strategy_probabilities(state, player_number) .= Types.opponent_strategy_recollection(state, player_number) ./ sum(Types.opponent_strategy_recollection(state, player_number))
    return nothing
end


function calculate_expected_utilities!(state::Types.State)
    @inbounds for column in axes(Types.payoff_matrix(model), 2) #column strategies #NOTE: could just do 1:size(model, dim=2) or something. might be a bit faster
        for row in axes(Types.payoff_matrix(state.model), 1) #row strategies
            Types.increment_expected_utilities!(state, 1, row, Types.payoff_matrix(state.model)[row, column][1] * Types.opponent_strategy_probabilities(state, 1, column))
            Types.increment_expected_utilities!(state, 2, column, Types.payoff_matrix(state.model)[row, column][2] * Types.opponent_strategy_probabilities(state, 2, row))
        end
    end
    return nothing
end


function make_choices!(state::Types.State) #NOTE: this might have to be defined by users for true generality
    for player_number in 1:2 #eachindex(model.pre_allocated_arrays.players)
        Types.rational_choice!(Types.players(state, player_number), maximum_strategy(Types.expected_utilities(state, player_number)))
        Types.choice!(Types.players(state, player_number), rand() < Types.error_rate(state.model) ? Types.random_strategy(state.model, player_number) : Types.rational_choice(Types.players(state, player_number)))
    end
end

function push_memory!(agent::Types.Agent, percept::Types.Percept, memory_length::Int)
    if length(Types.memory(agent)) >= memory_length
        popfirst!(Types.memory(agent))
    end
    push!(Types.memory(agent), percept)
    return nothing
end


function push_memories!(state::Types.State)
    push_memory!(Types.players(state, 1), Types.choice(Types.players(state, 2)), Types.memory_length(state.model))
    push_memory!(Types.players(state, 2), Types.choice(Types.players(state, 1)), Types.memory_length(state.model))
    return nothing
end


function maximum_strategy(expected_utilities::Vector{Float32})
    max_positions = Vector{Int}()
    max_val = Float32(0.)
    for i in eachindex(expected_utilities)
        if expected_utilities[i] > max_val
            max_val = expected_utilities[i]
            empty!(max_positions)
            push!(max_positions, i)
        elseif expected_utilities[i] == max_val
            push!(max_positions, i)
        end
    end
    return rand(max_positions)
end


function count_strategy(memory_set::Types.PerceptSequence, desired_strat::Integer)
    count::Int = 0
    for memory in memory_set
        if memory == desired_strat
            count += 1
        end
    end
    return count
end

