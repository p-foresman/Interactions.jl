const PayoffMatrix{S1, S2, L} = SMatrix{S1, S2, Tuple{Int, Int}, L} #reducing to {S1, S2} results in large slowdown



"""
    Game{S1, S2, L}

Basic Game type with row dimension S1 and column dimension S2.
"""
struct Game{S1, S2, L} #NOTE: ensure symmetric?? Make multiple types of games. Also need to update simulation engine to do more than symmetric games
    name::String
    payoff_matrix::PayoffMatrix{S1, S2, L}
    interaction_fn_name::String

    function Game{S1, S2, L}(name::String, payoff_matrix::PayoffMatrix{S1, S2, L}, interaction_fn_name::String) where {S1, S2, L}
        @assert isdefined(Registry.Games, Symbol(interaction_fn_name)) "'interaction_fn_name' provided does not correlate to a defined function in the Registry. Must use @interaction macro before function to register it"
        return new{S1, S2, L}(name, payoff_matrix, interaction_fn_name)
    end
    function Game(name::String, payoff_matrix::PayoffMatrix{S1, S2, L}, interaction_fn_name::String) where {S1, S2, L}
        @assert isdefined(Registry.Games, Symbol(interaction_fn_name)) "'interaction_fn_name' provided does not correlate to a defined function in the Registry. Must use @interaction macro before function to register it"
        return new{S1, S2, L}(name, payoff_matrix, interaction_fn_name)
    end
    function Game{S1, S2, L}(name::String, payoff_matrix::Matrix{Tuple{Int, Int}}, interaction_fn_name::String) where {S1, S2, L}
        @assert isdefined(Registry.Games, Symbol(interaction_fn_name)) "'interaction_fn_name' provided does not correlate to a defined function in the Registry. Must use @interaction macro before function to register it"
        static_payoff_matrix = PayoffMatrix{S1, S2, L}(payoff_matrix)
        return new{S1, S2, L}(name, static_payoff_matrix, interaction_fn_name)
    end
    function Game(name::String, payoff_matrix::Matrix{Tuple{Int, Int}}, interaction_fn_name::String)
        @assert isdefined(Registry.Games, Symbol(interaction_fn_name)) "'interaction_fn_name' provided does not correlate to a defined function in the Registry. Must use @interaction macro before function to register it"
        matrix_size = size(payoff_matrix)
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        L = S1 * S2
        static_payoff_matrix = PayoffMatrix{S1, S2, L}(payoff_matrix)
        return new{S1, S2, L}(name, static_payoff_matrix, interaction_fn_name)
    end
    # function Game(name::String, payoff_matrix::Matrix{Int}) #for a zero-sum payoff matrix ########################## MUST FIX THIS!!!!!!!! #####################
    #     matrix_size = size(payoff_matrix)
    #     S1 = matrix_size[1]
    #     S2 = matrix_size[2]
    #     L = S1 * S2
    #     indices = CartesianIndices(payoff_matrix)
    #     tuple_vector = Vector{Tuple{Int, Int}}([])
    #     for index in indices
    #         new_tuple = Tuple{Int, Int}([payoff_matrix[index], -payoff_matrix[index]])
    #         push!(tuple_vector, new_tuple)
    #     end
    #     new_payoff_matrix = reshape(tuple_vector, matrix_size)
    #     return new{S1, S2, L}(name, PayoffMatrix{S1, S2, L}(new_payoff_matrix))
    # end
end


##########################################
# Game Accessors
##########################################

"""
    name(game::Game)

Get the name of a game instance.
"""
name(game::Game) = getfield(game, :name)

"""
    payoff_matrix(game::Game)

Get the payoff matrix for a game.
"""
payoff_matrix(game::Game) = getfield(game, :payoff_matrix) #NOTE: type instability due to generic payoff matrix size


import Base.size #must import to extend
"""
    size(game::Game{S1, S2, L})

Returns a tuple containing the size of the game's payoff matrix, e.g., (3, 3)
"""
size(::Game{S1, S2, L}) where {S1, S2, L} = (S1, S2)

"""
    strategies(game::Game)

Get the possible strategies for each player that can be played in a game.
"""
strategies(game::Game) = axes(payoff_matrix(game))

"""
    strategies(game::Game, player_number::Int)

Get the possible strategies for the given player that can be played in a game.
"""
strategies(game::Game, player_number::Integer) = getindex(strategies(game), player_number) #NOTE: player number must be within dimensions of payoff_matrix. Might want to go through and do error handling stuff (would add extra overhead though)

"""
    random_strategy(game::Game, player_number::Int)

Get a random strategy from the possible strategies that a player can play in a game.
"""
random_strategy(game::Game, player_number::Integer) = rand(strategies(game, player_number))



"""
    interaction_fn_name(game::Game)

Get the 'interaction_fn_name' Game field.
"""
interaction_fn_name(game::Game) = getfield(game, :interaction_fn_name)

"""
    interaction_fn(game::Game)

Get the user-defined interaction function which correlates to the String stored in the 'interaction_fn_name' Game field.
"""
interaction_fn(game::Game) = getfield(Registry.Games, Symbol(interaction_fn_name(game)))


Base.show(game::Game) = println(name(game))
