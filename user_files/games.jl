
@interaction function maximum_strategy(expected_utilities::Vector{Float64})
        max_positions = Vector{Int}()
        max_val = 0.0
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


@interaction function count_strategy(memory_set::Interactions.Types.PerceptSequence, desired_strat::Integer)
    count::Int = 0
    for memory in memory_set
        if memory == desired_strat
            count += 1
        end
    end
    return count
end

#other player isn't even needed without tags. this could be simplified
@interaction function calculate_opponent_strategy_probabilities!(state::Interactions.Types.State, player_number::Integer)
    @inbounds for memory in Interactions.Types.memory(Interactions.Types.players(state, player_number))
        Interactions.Types.increment_arrays!(state, :opponent_strategy_recollection, player_number, memory) #memory strategy is simply the payoff_matrix index for the given dimension
    end
    Interactions.Types.arrays(state, :opponent_strategy_probabilities, player_number) .= Interactions.Types.arrays(state, :opponent_strategy_recollection, player_number) ./ sum(Interactions.Types.arrays(state, :opponent_strategy_recollection, player_number))
    return nothing
end

@interaction function find_opponent_strategy_probabilities!(state::Interactions.Types.State)
    for player_number in 1:2 #NOTE: only functional for 2 players!
        calculate_opponent_strategy_probabilities!(state, player_number)
    end
    return nothing
end



@interaction function calculate_expected_utilities!(state::Interactions.Types.State)
    @inbounds for column in axes(Interactions.Types.payoff_matrix(Interactions.Types.model(state)), 2) #column strategies #NOTE: could just do 1:size(model, dim=2) or something. might be a bit faster
        for row in axes(Interactions.Types.payoff_matrix(state.model), 1) #row strategies
            Interactions.Types.increment_arrays!(state, :expected_utilities, 1, row, Interactions.Types.payoff_matrix(Interactions.Types.model(state))[row, column][1] * Interactions.Types.arrays(state, :opponent_strategy_probabilities, 1, column))
            Interactions.Types.increment_arrays!(state, :expected_utilities, 2, column, Interactions.Types.payoff_matrix(Interactions.Types.model(state))[row, column][2] * Interactions.Types.arrays(state, :opponent_strategy_probabilities, 2, row))

            # Interactions.Types.increment_expected_utilities!(state, 1, row, Interactions.Types.payoff_matrix(Interactions.Types.model(state))[row, column][1] * Interactions.Types.opponent_strategy_probabilities(state, 1, column))
            # Interactions.Types.increment_expected_utilities!(state, 2, column, Interactions.Types.payoff_matrix(Interactions.Types.model(state))[row, column][2] * Interactions.Types.opponent_strategy_probabilities(state, 2, row))
            
            
            
            # p1_payoff = @timeit to "payoff_matrix" Interactions.Types.payoff_matrix(Interactions.Types.model(state))[row, column][1]
            # p2_payoff = @timeit to "payoff_matrix" Interactions.Types.payoff_matrix(Interactions.Types.model(state))[row, column][2]
            # p1_weight = @timeit to "opponent_strategy_probabilities" Interactions.Types.opponent_strategy_probabilities(state, 1, column)
            # p2_weight = @timeit to "opponent_strategy_probabilities" Interactions.Types.opponent_strategy_probabilities(state, 2, row)
            # @timeit to "increment_expected_utilities" Interactions.Types.increment_expected_utilities!(state, 1, row, p1_payoff * p1_weight)
            # @timeit to "increment_expected_utilities" Interactions.Types.increment_expected_utilities!(state, 2, column, p2_payoff * p2_weight)
        end
    end
    return nothing
end


@interaction function make_choices!(state::Interactions.Types.State) #NOTE: this might have to be defined by users for true generality
    for player_number in 1:2 #eachindex(model.pre_allocated_arrays.players)
        Interactions.Types.rational_choice!(Interactions.Types.players(state, player_number), maximum_strategy(Interactions.Types.arrays(state, :expected_utilities, player_number)))
        Interactions.Types.choice!(Interactions.Types.players(state, player_number), rand() < Interactions.Types.parameters(state, :error_rate) ? Interactions.Types.random_strategy(state.model, player_number) : Interactions.Types.rational_choice(Interactions.Types.players(state, player_number)))
    end
end

@interaction function push_memory!(agent::Interactions.Types.Agent, percept::Interactions.Types.Percept, memory_length::Int)
    if length(Interactions.Types.memory(agent)) >= memory_length
        popfirst!(Interactions.Types.memory(agent))
    end
    push!(Interactions.Types.memory(agent), percept)
    return nothing
end


@interaction function push_memories!(state::Interactions.Types.State)
    push_memory!(Interactions.Types.players(state, 1), Interactions.Types.choice(Interactions.Types.players(state, 2)), Int(Interactions.Types.parameters(state, :memory_length)))
    push_memory!(Interactions.Types.players(state, 2), Interactions.Types.choice(Interactions.Types.players(state, 1)), Int(Interactions.Types.parameters(state, :memory_length)))
    return nothing
end

@interaction function play_game!(state::Interactions.Types.State)




    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.
    find_opponent_strategy_probabilities!(state)
    calculate_expected_utilities!(state)
    make_choices!(state)
    push_memories!(state)
    # @timeit to "find_opponent_strategy_probabilities" find_opponent_strategy_probabilities!(state)
    # @timeit to "calculate_expected_utilities" calculate_expected_utilities!(state; to=to)
    # @timeit to "make_choices" make_choices!(state; to=to)
    # @timeit to "push_memories" push_memories!(state)
    return nothing
end