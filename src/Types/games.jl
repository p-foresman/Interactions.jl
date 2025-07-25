const PayoffMatrix{S1, S2, L} = SMatrix{S1, S2, Tuple{Int, Int}, L} #NOTE: try to reduce this to drop the L since L=S1*S2



"""
    Game{S1, S2, L}

Basic Game type with row dimension S1 and column dimension S2.
"""
struct Game{S1, S2, L} #NOTE: ensure symmetric?? Make multiple types of games. Also need to update simulation engine to do more than symmetric games
    name::String
    payoff_matrix::PayoffMatrix{S1, S2, L}
    # play_game::String

    function Game{S1, S2, L}(name::String, payoff_matrix::PayoffMatrix{S1, S2, L}) where {S1, S2, L}
        return new{S1, S2, L}(name, payoff_matrix)
    end
    function Game(name::String, payoff_matrix::PayoffMatrix{S1, S2, L}) where {S1, S2, L}
        return new{S1, S2, L}(name, payoff_matrix)
    end
    function Game{S1, S2, L}(name::String, payoff_matrix::Matrix{Tuple{Int, Int}}) where {S1, S2, L}
        static_payoff_matrix = PayoffMatrix{S1, S2, L}(payoff_matrix)
        return new{S1, S2, L}(name, static_payoff_matrix)
    end
    function Game(name::String, payoff_matrix::Matrix{Tuple{Int, Int}})
        matrix_size = size(payoff_matrix)
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        L = S1 * S2
        static_payoff_matrix = PayoffMatrix{S1, S2, L}(payoff_matrix)
        return new{S1, S2, L}(name, static_payoff_matrix)
    end
    function Game(name::String, payoff_matrix::Matrix{Int}) #for a zero-sum payoff matrix ########################## MUST FIX THIS!!!!!!!! #####################
        matrix_size = size(payoff_matrix)
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        L = S1 * S2
        indices = CartesianIndices(payoff_matrix)
        tuple_vector = Vector{Tuple{Int, Int}}([])
        for index in indices
            new_tuple = Tuple{Int, Int}([payoff_matrix[index], -payoff_matrix[index]])
            push!(tuple_vector, new_tuple)
        end
        new_payoff_matrix = reshape(tuple_vector, matrix_size)
        return new{S1, S2, L}(name, PayoffMatrix{S1, S2, L}(new_payoff_matrix))
    end
end


##########################################
# Game Accessors
##########################################

"""
    displayname(game::Game)

Get the name of a game instance.
"""
displayname(game::Game) = getfield(game, :name)

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


Base.show(game::Game) = println(displayname(game))
