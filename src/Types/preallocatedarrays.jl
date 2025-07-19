# const Players = Vector{Agent}

"""
    Interactions.PreAllocatedArrays

Type to pre-allocate vectors for simulation calculations, thus improving performance.
"""
struct PreAllocatedArrays #{N} #N is number of players (optimize for 2?) #NOTE: should i store these with invividual agents??? Could call this GameState?
    players::Vector{Agent} #NOTE: should this just store indices to look up agents?
    opponent_strategy_recollection::SVector{2, Vector{Int}}
    opponent_strategy_probs::SVector{2, Vector{Float64}}
    player_expected_utilities::SVector{2, Vector{Float32}}

    function PreAllocatedArrays(g::Game)
        sizes = size(g)
        N = length(sizes)
        players = Vector{Agent}([Agent() for _ in 1:N]) #should always be 2
        opponent_strategy_recollection = SVector{N, Vector{Int}}(zeros.(Int, sizes))
        opponent_strategy_probs = SVector{N, Vector{Float64}}(zeros.(Float64, sizes))
        player_expected_utilities = SVector{N, Vector{Float32}}(zeros.(Float32, sizes))
        return new(players, opponent_strategy_recollection, opponent_strategy_probs, player_expected_utilities)
    end
end


##########################################
# PreAllocatedArrays Accessors
##########################################


"""
    players(preallocatedarrays::PreAllocatedArrays)

Get the currently cached players involved in a game.
"""
players(preallocatedarrays::PreAllocatedArrays) = getfield(preallocatedarrays, :players)

"""
    players(preallocatedarrays::PreAllocatedArrays, player_number::Integer)

Get the currently cached player indexed by player_number.
"""
players(preallocatedarrays::PreAllocatedArrays, player_number::Integer) = getindex(players(preallocatedarrays), player_number)

"""
    player!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, agent::Agent)

Set an agent as a player indexed by player_number.
"""
player!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, agent::Agent) = setindex!(players(preallocatedarrays), agent, player_number)

"""
    opponent_strategy_recollection(preallocatedarrays::PreAllocatedArrays)

Get the currently cached recollections of each player (i.e., the quantity of each strategy that resides in players' memories).
"""
opponent_strategy_recollection(preallocatedarrays::PreAllocatedArrays) = getfield(preallocatedarrays, :opponent_strategy_recollection)

"""
    opponent_strategy_recollection(preallocatedarrays::PreAllocatedArrays, player_number::Integer)

Get the currently cached recollection of the player indexed by player_number.
"""
opponent_strategy_recollection(preallocatedarrays::PreAllocatedArrays, player_number::Integer) = getindex(opponent_strategy_recollection(preallocatedarrays), player_number)

"""
    opponent_strategy_recollection(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer)

Get the currently cached recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer) = getindex(opponent_strategy_recollection(preallocatedarrays, player_number), index)

"""
    opponent_strategy_recollection!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::Int)

Set the recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::Int) = setindex!(opponent_strategy_recollection(preallocatedarrays, player_number), value, index)

"""
    increment_opponent_strategy_recollection!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::Int=1)

Increment the recollection of a strategy indexed by index of the player indexed by player_number by value (defaults to an increment of 1).
"""
increment_opponent_strategy_recollection!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::Int=1) = opponent_strategy_recollection!(preallocatedarrays, player_number, index, opponent_strategy_recollection(preallocatedarrays, player_number, index) + value)

"""
    opponent_strategy_probabilities(preallocatedarrays::PreAllocatedArrays)

Get the currently cached probabilities that each player's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(preallocatedarrays::PreAllocatedArrays) = getfield(preallocatedarrays, :opponent_strategy_probs)

"""
    opponent_strategy_probabilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer)

Get the currently cached probabilities that the player indexed by player_number's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer) = getindex(opponent_strategy_probabilities(preallocatedarrays), player_number)

"""
    opponent_strategy_probabilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer)

Get the currently cached probability that the player indexed by player_number's opponent will play the strategy indexed by index.
"""
opponent_strategy_probabilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer) = getindex(opponent_strategy_probabilities(preallocatedarrays, player_number), index)

"""
    expected_utilities(preallocatedarrays::PreAllocatedArrays)

Get the cached expected utilities for playing each strategy for both players.
"""
expected_utilities(preallocatedarrays::PreAllocatedArrays) = getfield(preallocatedarrays, :player_expected_utilities)

"""
    expected_utilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer)

Get the cached expected utilities for playing each strategy for the player indexed by player_number.
"""
expected_utilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer) = getindex(expected_utilities(preallocatedarrays), player_number)

"""
    expected_utilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer)

Get the cached expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer) = getindex(expected_utilities(preallocatedarrays, player_number), index)

"""
    expected_utilities!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::AbstractFloat)

Set the expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::AbstractFloat) = setindex!(expected_utilities(preallocatedarrays, player_number), value, index) #not sure if abstract float is good here

"""
    increment_expected_utilities!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::AbstractFloat)

Increment the expected utility for playing the strategy indexed by index for the player indexed by player_number by value.
"""
increment_expected_utilities!(preallocatedarrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::AbstractFloat) = expected_utilities!(preallocatedarrays, player_number, index, expected_utilities(preallocatedarrays, player_number, index) + value)

"""
    reset_arrays!(preallocatedarrays::PreAllocatedArrays)

Reset the cached arrays in an PreAllocatedArrays instance to zeros.
"""
function reset_arrays!(preallocatedarrays::PreAllocatedArrays)
    for player_number in 1:2
        # preallocatedarrays.players[player] = nothing
        opponent_strategy_recollection(preallocatedarrays, player_number) .= Int(0)
        opponent_strategy_probabilities(preallocatedarrays, player_number) .= Float64(0)
        expected_utilities(preallocatedarrays, player_number) .= Float32(0)
    end
    return nothing
end