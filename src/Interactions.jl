"""
    Interactions

Package used to simulate games over network interaction structures.
"""
module Interactions

#basic utility functions
include("utility.jl")

#extensions of Graphs.jl graph constructors
include("GraphsExt/GraphsExt.jl")
# import .GraphsExt

include("Registry/Registry.jl")
using .Registry: @graphmodel, @startingcondition, @stoppingcondition
export @graphmodel, @startingcondition, @stoppingcondition

#types used in Interactions
include("Types/Types.jl")
using .Types
export 
    PayoffMatrix,
    Game,
    displayname,
    payoff_matrix,
    strategies,
    random_strategy,

    GraphModel,

    Model,
    model,
    Parameters,
    parameters,
    Variables,
    variables,
    variables!,
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


#include StructTypes for reconstructing custom structures
# include("settings/structtypes.jl")

# global SETTINGS

#api to sqlite and postgresql functionality
include("Database/Database.jl")

#include Generators
include("Generators/Generators.jl")
#using .Generators

#include default config and configure
include("settings/config.jl")

#simulation functions
include("Simulate/Simulate.jl")
using .Simulate: simulate, count_strategy
export simulate

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