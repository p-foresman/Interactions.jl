"""
    Types

Module containg the core data structures for the Interactions.jl package
"""
module Types

export
    #Game stuff
    PayoffMatrix,
    Game,
    displayname, #multi-use
    payoff_matrix,
    strategies,
    random_strategy

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
    ..GraphsExt,
    ..Registry
    

include("games.jl")
include("parameters.jl")
include("interactionmodels.jl")
include("agents.jl")
include("agentgraph.jl")
include("preallocatedarrays.jl")
include("model.jl")
include("state.jl")

end #Types



#NOTE: remove when ready
"""
export
    # types
    Model,
    Models,
    Game,
    Parameters,
    GraphModel,

    # accessors
    displayname,


    #old
    game,
    payoff_matrix,
    size,
    strategies,
    random_strategy,

    graphmodel,


    parameters,
    number_agents,
    memory_length,
    error_rate,
    matches_per_period,
    random_seed,
    UserVariables,
    user_variables,
    set_user_variable!,

    # startingcondition,
    type, #rename?


    period,


    # agentgraph,
    # graph,
    agents,
    # # edges, #rename?
    # random_edge,
    # components,
    # num_components,
    # # component_vertex_sets,
    # # component_edge_sets,
    # # random_component_edge,
    number_hermits,

    ishermit, #these accessors only implemented for Agent, should they be implemented for Model too?
    memory,
    generate_graph,
    generate_graph!,
    # rational_choice,
    # rational_choice!,
    # choice,
    # choice!,

    # preallocatedarrays,
    # players,
    # player!,
    # set_players!,
    # opponent_strategy_recollection,
    # opponent_strategy_recollection!,
    # increment_opponent_strategy_recollection!,
    # opponent_strategy_probabilities,
    # expected_utilities,
    # expected_utilities!,
    # increment_expected_utilities!,
    # reset_arrays!,

    # period,
    # period!,
    # increment_period,

    graph,
    graph!
    # reset_model!,
    # regenerate_model,

"""