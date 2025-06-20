
############################### FUNCTIONS #######################################

#state is only mutated within the scope of this function (using multiple dispatch for to optimize main simulation loop)
function simulate!(state::State, ::Nothing, ::Nothing; stopping_condition_reached::Function)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::State, timeout::Int, ::Nothing; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Interactions.timedout!(state)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::State, ::Nothing, db_push_period::Int; stopping_condition_reached::Function)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif iszero(period(state) % db_push_period)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::State, timeout::Int, db_push_period::Int; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Interactions.timedout!(state)
            break
        elseif iszero(period(state) % db_push_period)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end



######################## game algorithm ####################
function run_period!(model::Model, state::State)
    for component in Interactions.components(state) #each connected component plays its own period's worth of matches
        # mpp = matches_per_period(num_vertices(component)) * edge_density(num_vertices(component), λ(graph_parameters(model))) #NOTE: CHANGE THIS BACK
        # for _ in 1:Int(ceil(mpp))
        for _ in 1:matches_per_period(component)
            Interactions.reset_arrays!(state)
            Interactions.set_players!(state, component)
            play_game!(model, state)
        end
    end
    Interactions.increment_period!(state)
    return nothing
end



function play_game!(model::Model, state::State)
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.
    find_opponent_strategy_probabilities!(state)
    calculate_expected_utilities!(model, state)
    make_choices!(model, state)
    push_memories!(model, state)
    return nothing
end

function find_opponent_strategy_probabilities!(state::State)
    for player_number in 1:2 #NOTE: only functional for 2 players!
        calculate_opponent_strategy_probabilities!(state, player_number)
    end
    return nothing
end


#other player isn't even needed without tags. this could be simplified
function calculate_opponent_strategy_probabilities!(state::State, player_number::Integer)
    @inbounds for memory in memory(Interactions.players(state, player_number))
        Interactions.increment_opponent_strategy_recollection!(state, player_number, memory) #memory strategy is simply the payoff_matrix index for the given dimension
    end
    Interactions.opponent_strategy_probabilities(state, player_number) .= Interactions.opponent_strategy_recollection(state, player_number) ./ sum(Interactions.opponent_strategy_recollection(state, player_number))
    return nothing
end


function calculate_expected_utilities!(model::Model, state::State)
    @inbounds for column in axes(payoff_matrix(model), 2) #column strategies #NOTE: could just do 1:size(model, dim=2) or something. might be a bit faster
        for row in axes(payoff_matrix(model), 1) #row strategies
            Interactions.increment_expected_utilities!(state, 1, row, payoff_matrix(model)[row, column][1] * Interactions.opponent_strategy_probabilities(state, 1, column))
            Interactions.increment_expected_utilities!(state, 2, column, Interactions.payoff_matrix(model)[row, column][2] * Interactions.opponent_strategy_probabilities(state, 2, row))
        end
    end
    return nothing
end


function make_choices!(model::Model, state::State)
    for player_number in 1:2 #eachindex(model.pre_allocated_arrays.players)
        Interactions.rational_choice!(Interactions.players(state, player_number), maximum_strategy(Interactions.expected_utilities(state, player_number)))
        Interactions.choice!(Interactions.players(state, player_number), rand() < Interactions.error_rate(model) ? Interactions.random_strategy(model, player_number) : Interactions.rational_choice(Interactions.players(state, player_number)))
    end
end

function push_memory!(agent::Agent, percept::Interactions.Percept, memory_length::Int)
    if length(memory(agent)) >= memory_length
        popfirst!(memory(agent))
    end
    push!(memory(agent), percept)
    return nothing
end


function push_memories!(model::Model, state::State)
    push_memory!(Interactions.players(state, 1), Interactions.choice(Interactions.players(state, 2)), memory_length(model))
    push_memory!(Interactions.players(state, 2), Interactions.choice(Interactions.players(state, 1)), memory_length(model))
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


function count_strategy(memory_set::Interactions.PerceptSequence, desired_strat::Integer)
    count::Int = 0
    for memory in memory_set
        if memory == desired_strat
            count += 1
        end
    end
    return count
end

