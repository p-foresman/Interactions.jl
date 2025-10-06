"""
    ModelGenerator

A type to store the values for a parameter sweep. Can be used to populate a database with model data and to generate a model given an index.
"""
struct ModelGenerator <: Generator
    agent_type::Type{<:Types.AbstractAgent}
    population_sizes::Vector{Int}
    game::Types.Game
    graphmodel::Symbol # can only generate with one graph model per model generator for now due to the implementation of parameters
    starting_condition::Symbol
    stopping_condition::Symbol
    parameters::Dict{Symbol, Vector{Float64}} # this is what we're sweeping over
    variables::Types.Variables #the variables used in the model (these variables can be altered during the course of a simulation)
    arrays::Types.Arrays
    size::Int

    function ModelGenerator(
        agent_type::Type{<:Types.AbstractAgent},
        population_sizes::Vector{Int},
        game::Types.Game,
        graphmodel::Symbol,
        starting_condition::Symbol,
        stopping_condition::Symbol,
        parameters::Dict{Symbol, Vector};
        variables::Types.Variables=Types.Variables(),
        arrays::Types.Arrays=Types.Arrays()
    )   
        sz = sum(Interactions.volume(population_sizes, values(parameters)...))
        return new(agent_type, population_sizes, game, graphmodel, starting_condition, stopping_condition, parameters, variables, arrays, sz)
    end
end

# Base.size(generator::ModelGenerator) = getfield(generator, :size) #NOTE: could have one size function for all generators


function generate_model(generator::ModelGenerator, index::Integer) #NOTE: could use iterator method here too, but would be much less efficient
    count = 0

    # ensure that params and vals are in the same order for Iterators.product
    params = sort!(collect(keys(generator.parameters)))
    vals = []
    for param in params
        push!(vals, generator.parameters[param])
    end

    for population_size in generator.population_sizes
        for parameter_combination in Iterators.product(vals...)
            count += 1
            if count == index
                return Types.Model(generator.agent_type,
                                    population_size, 
                                    generator.game, 
                                    generator.graphmodel, 
                                    generator.starting_condition, 
                                    generator.stopping_condition;
                                    parameters = Types.Parameters(zip(params, parameter_combination)),
                                    variables = generator.variables,
                                    arrays = generator.arrays
                                    )
            end
        end
    end
    return nothing
end

function generate_database(generator::ModelGenerator)
   
    # ensure that params and vals are in the same order for Iterators.product
    params = sort!(collect(keys(generator.parameters)))
    vals = []
    for param in params
        push!(vals, generator.parameters[param])
    end

    for population_size in generator.population_sizes
        for parameter_combination in Iterators.product(vals...)
            model = Types.Model(generator.agent_type,
                                population_size, 
                                generator.game, 
                                generator.graphmodel, 
                                generator.starting_condition, 
                                generator.stopping_condition;
                                parameters = Types.Parameters(zip(params, parameter_combination)),
                                variables = generator.variables,
                                arrays = generator.arrays
                                )
            Database.insert_model(model)
        end
    end
    return nothing
end



struct ModelGeneratorSet <: Generator
    generators::Vector{ModelGenerator}
    size::Int #store size for ease of retrieval later

    function ModelGeneratorSet(generators::ModelGenerator...) #; multiplier::Integer=1) #NOTE: didn't implement multiplier yet but could
        count = 0
        for generator in generators
            count += generator.size
        end
        return new(collect(generators), count)
    end
end

#NOTE: implement getindex for these generators as well!
function generate_model(generator_set::ModelGeneratorSet, index::Integer)
    prev = 0
    cutoff = 0
    for generator in generator_set.generators
        cutoff += generator.size
        if index <= cutoff
            return generate_model(generator, index - prev)
        end
        prev = cutoff
    end
    return nothing
end


#NOTE: these are fun but don't really need them (they dont fully work)
# Base.:+(generator::ModelGenerator, others::ModelGenerator...) = ModelGeneratorSet(push!([generator], others...)...)
# Base.:+(generator_set::ModelGeneratorSet, generators::ModelGenerator...) = ModelGeneratorSet(vcat(generator_set.generators, generators...)...) #+(generator_set.generators..., generators...)
# function Base.:+(generator_set::ModelGeneratorSet, others::ModelGeneratorSet...)
#     new_set = generator_set.generators
#     for other in others
#         push!(new_set, other.generators...)
#     end
#     return ModelGeneratorSet(new_set...)
# end
# function Base.:+(generator::ModelGenerator, generator_sets::ModelGeneratorSet...) #need this one for all combos
#     new_set = popfirst!(collect(generator_sets))
#     for set in generator_sets

#     end
# end





"""
    get_model_id(process_num, num_processes_in_job)

Used in high-throughput computing jobs
"""
function get_model_id(process_num, num_processes_in_job) #NOTE: remove?
    return (process_num % num_processes_in_job) + 1
end