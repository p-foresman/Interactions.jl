module Generators

export
    GraphModelGenerator,
    ModelGenerator,
    ModelGeneratorSet,
    generate_model,
    get_model_id #NOTE: this one is specific for my stuff on OSG, maybe delete

import
    ..Types,
    ..Database,
    ..Registry,
    ..GraphsExt,
    ..Interactions

# using ..Interactions

abstract type Generator end #supertype to all generators

include("graphmodel_generators.jl")
include("model_generators.jl")

Base.size(generator::Generator) = getfield(generator, :size) #NOTE: could have one size function for all generators

function Base.iterate(generator::Generator, state=1) #iterate over any <:Generator instance
    if state > generator.size
        return nothing
    else
        return (generate_model(generator, state), state + 1)
    end    
end

end #Generators