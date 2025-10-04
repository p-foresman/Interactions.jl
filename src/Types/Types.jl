"""
    Types

Module containg the core data structures for the Interactions.jl package
"""
module Types

export
    #Game stuff
    PayoffMatrix,
    Game,
    name, #multi-use
    payoff_matrix,
    strategies,
    random_strategy,

    # GraphModel,

    Model,
    model,
    Parameters,
    parameters,
    Variables,
    variables,
    variables!,
    Arrays,
    arrays,
    arrays!,
    increment_arrays!,
    agents,
    ishermit,
    ishermit!,
    number_hermits,
    State,
    population_size,
    rational_choice,
    rational_choice!,
    choice,
    choice!,
    memory,
    period

    #Agent stuff

using
    # ..Interactions,
    Random,
    # DataFrames,
    # SQLite,
    # LibPQ,
    StaticArrays,
    Distributed,
    DataStructures,
    JSON3,
    # Memoize,
    InteractiveUtils,
    TimerOutputs, #NOTE: get rid of this
    Suppressor, #NOTE: get rid of this? (used in config i guess),
    ParallelDataTransfer
    

import
    Graphs,
    ..Registry
    

include("games.jl")
# include("interactionmodels.jl")
include("agents.jl")
include("agentgraph.jl")
include("model.jl")
include("state.jl")

end #Types