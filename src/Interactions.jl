"""
    Interactions

Package used to simulate games over network interaction structures.
"""
module Interactions

#basic utility functions
include("utility.jl")

include("Registry/Registry.jl")
using .Registry: @graphmodel, @startingcondition, @stoppingcondition, @interaction
export @graphmodel, @startingcondition, @stoppingcondition, @interaction

#types used in Interactions
include("Types/Types.jl")
using .Types
export 
    PayoffMatrix,
    Game,
    name,
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


#api to sqlite and postgresql functionality
include("Database/Database.jl")
export Database

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