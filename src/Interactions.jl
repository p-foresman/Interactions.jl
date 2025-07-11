"""
    Interactions

Package used to simulate games over network interaction structures.
"""
module Interactions

export
    # types
    Model,
    Models,
    Game,
    Parameters,
    GraphModel,
    Agent,
    State, #should this be exported? (NOTE: currently needs to be for other modules, fix this)
    AgentGraph, #should this be exported?

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

    # stoppingcondition,
    # strategy, #rename?
    # sufficient_equity,
    # sufficient_equity!,
    # sufficient_transitioned,
    # sufficient_transitioned!,
    # period_cutoff,
    # period_cutoff!,
    # period_count,
    # period_count!,
    # increment_period_count!,

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
    graph!,
    displayname,
    # reset_model!,
    # regenerate_model,

    # constructors
    construct_sim_params_list,
    construct_model_list,
    select_and_construct_model,

    #NOTE: make Generators submodule
    ModelGenerator,
    ErdosRenyiModelGenerator,
    SmallWorldModelGenerator,
    ScaleFreeModelGenerator,
    StochasticBlockModelGenerator,

    ####################

    #simulation
    simulate,
    count_strategy,

    # simulate_distributed,
    # simulation_iterator,

    # determine_agent_behavior, #NOTE: FIX THIS

    #database api
    # db_init,
    # db_insert_sim_group,
    # db_collect_temp,
    # db_execute,
    # db_query,

    #plotting
    # transitionTimesBoxPlot,
    # memoryLengthTransitionTimeLinePlot,
    # numberAgentsTransitionTimeLinePlot,
    # timeSeriesPlot,
    # multipleTimeSeriesPlot,

    #utility
    OrNothing,
    resetprocs,

    #graph constructors
    # erdos_renyi_rg,
    # small_world_rg,
    # scale_free_rg,
    # stochastic_block_model_rg,

    # from Generators
    # CompleteModelGenerator,
    # ErdosRenyiModelGenerator,
    # SmallWorldModelGenerator,
    # ScaleFreeModelGenerator,
    # StochasticBlockModelGenerator,
    # ModelGenerator,
    # ModelGeneratorSet,
    # generate_model,
    # get_model_id,

    # Model, #NOTE: do we want this, or do we want to expose the methods from this in the core of Interactions?
    Database,
    Analyze,

    @graphmodel,
    @startingcondition,
    @stoppingcondition


using
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

#basic utility functions
include("utility.jl")

#extensions of Graphs.jl graph constructors
include("GraphsExt/GraphsExt.jl")
import .GraphsExt

include("Registry/Registry.jl")
import .Registry: @graphmodel, @startingcondition, @stoppingcondition

#core of Interactions
include("games.jl")
include("parameters.jl")
include("interactionmodels.jl")
include("agents.jl")
include("agentgraph.jl")
include("preallocatedarrays.jl")
include("model.jl")
include("state.jl")
include("structtypes.jl")


#include StructTypes for reconstructing custom structures
# include("settings/structtypes.jl")

global SETTINGS #NOTE: want to eventually remove this. Was running into issues with SETTINGS not being imported to Database submodule (get rid of modules?)

#api to sqlite and postgresql functionality
include("Database/Database.jl")

#include Generators
include("Generators/Generators.jl")
using .Generators

#include default config and configure
include("settings/config.jl")

#simulation functions
include("Simulate/Simulate.jl")
import .Simulate: simulate, count_strategy

#Analyze module contains analysis and plotting functions
# include("Analyze/Analyze.jl")


function __init__()
    if haskey(ENV, "TEST_INTERACTIONS") && parse(Bool, ENV["TEST_INTERACTIONS"]) #if testing, use the test config
        @suppress configure("./config/test_config.toml")
    else
        configure()
    end
end

end #Interactions