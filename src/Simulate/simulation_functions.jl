
############################### FUNCTIONS #######################################



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








# matches_per_period(N::Integer) = Int(floor(N / 2)) #NOTE: hard coded for now (put this in the ConnectedComponent struct)


# function run_period!(model::Model)
#     run_period!(model, graph_parameters(model)) #multiple dispatch
#     return nothing
# end


# function run_period!(model::Model, state::State)
#         # mpp = matches_per_period(num_vertices(component)) * edge_density(num_vertices(component), λ(graph_parameters(model))) #NOTE: CHANGE THIS BACK
#         # for _ in 1:Int(ceil(mpp))
#     for _ in 1:agentgraph(state).matches_per_period
#         reset_arrays!(state)
#         set_players!(state)
#         play_game!(model, state)
#     end
#     increment_period!(state)
#     return nothing
# end

# function run_period!(model::Model, ::CompleteParams) #no chance of multiple components, can optimize
#     for _ in 1:matches_per_period(model) #cached (should cache for each component!!)
#         reset_arrays!(model)
#         # set_players!(model, components(model, 1)) #only one component
#         set_players!(model)
#         play_game!(model)
#     end
#     return nothing
# end







# with tag functionality
# function calculateOpponentStrategyProbs!(player_memory, opponent_tag, opponent_strategy_recollection, opponent_strategy_probs)
#     @inbounds for memory in player_memory
#         if memory[1] == opponent_tag #if the opponent's tag is not present, no need to count strategies
#             opponent_strategy_recollection[memory[2]] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
#         end
#     end
#     opponent_strategy_probs .= opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
#     return nothing
# end











######################## STUFF FOR DETERMINING AGENT BEHAVIOR (should combine this with above functions in the future) ###############################

# function calculateExpectedOpponentProbs(::Game{S1, S2}, memory_set::PerceptSequence) where {S1, S2}
#     # length = size(game.payoff_matrix, 1) #for symmetric games only
#     opponent_strategy_recollection = zeros(Int, S1)
#     for memory in memory_set
#         opponent_strategy_recollection[memory] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
#     end
#     opponent_strategy_probs = opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
#     return opponent_strategy_probs
# end


# function calculateExpectedUtilities(game::Game{S1, S2}, opponent_probs) where {S1, S2} #for symmetric games only!
#     payoff_matrix = payoff_matrix(game)
#     player_expected_utilities = zeros(Float32, S1)
#     @inbounds for column in axes(payoff_matrix(game), 2) #column strategies
#         for row in axes(payoff_matrix(game), 1) #row strategies
#             player_expected_utilities[row] += payoff_matrix[row, column][1] * opponent_probs[column]
#         end
#     end
#     return player_expected_utilities
# end


# function determine_agent_behavior(game::Game, memory_set::PerceptSequence)
#     opponent_strategy_probs = calculateExpectedOpponentProbs(game, memory_set)
#     expected_utilities = calculateExpectedUtilities(game, opponent_strategy_probs)
#     max_strat = maximum_strategy(expected_utilities) #right now, if more than one strategy results in a max expected utility, a random strategy is chosen of the maximum strategies
#     return max_strat
# end

########### tagged memory stuff #####
# function calculateExpectedOpponentProbs(::Game{S1, S2, L}, memory_set::PerceptSequence) where {S1, S2, L}
#     # length = size(game.payoff_matrix, 1) #for symmetric games only
#     opponent_strategy_recollection = zeros(Int, S1)
#     for memory in memory_set
#         opponent_strategy_recollection[memory[2]] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
#     end
#     opponent_strategy_probs = opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
#     return opponent_strategy_probs
# end

# function determineAgentBehavior(game::Game, memory_set::Vector{Tuple{Symbol, Int8}})
#     opponent_strategy_probs = calculateExpectedOpponentProbs(game, memory_set)
#     expected_utilities = calculateExpectedUtilities(game, opponent_strategy_probs)
#     max_strat = findMaximumStrats(expected_utilities) #right now, if more than one strategy results in a max expected utility, a random strategy is chosen of the maximum strategies
#     return max_strat
# end

#######################################################

# function is_stopping_condition(state::State, stoppingcondition::EquityPsychological) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
#     number_transitioned = 0
#     for agent in agents(state)
#         if !ishermit(agent)
#             if count_strategy(memory(agent), strategy(stoppingcondition)) >= sufficient_equity(stoppingcondition) #this is hard coded to strategy 2 (M) for now. Should change later!
#                 number_transitioned += 1
#             end
#         end
#     end 
#     return number_transitioned >= sufficient_transitioned(stoppingcondition)
# end

# function is_stopping_condition(state::State, stoppingcondition::EquityBehavioral) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
#     number_transitioned = 0
#     for agent in agents(state)
#         if !ishermit(agent)
#             if rational_choice(agent) == strategy(stoppingcondition) #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
#                 number_transitioned += 1
#             end
#         end
#     end 

#     if number_transitioned >= sufficient_transitioned(stoppingcondition)
#         increment_period_count!(stoppingcondition)
#         return period_count(stoppingcondition) >= period_cutoff(stoppingcondition)
#     else
#         period_count!(stoppingcondition, 0) #reset period count
#         return false
#     end
# end



# function is_stopping_condition(state::State, stoppingcondition::PeriodCutoff)
#     return period(state) >= period_cutoff(stoppingcondition)
# end



#tagged functionality
# function countStrats(memory_set::Vector{Tuple{Symbol, Int8}}, desired_strat)
#     count::Int = 0
#     for memory in memory_set
#         if memory[2] == desired_strat
#             count += 1
#         end
#     end
#     return count
# end

