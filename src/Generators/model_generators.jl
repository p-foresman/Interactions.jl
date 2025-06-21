"""
    ModelGenerator

A type to store the values for a parameter sweep. Can be used to populate a database with model data and to generate a model given a model id.
"""
struct ModelGenerator <: Generator
    game::Game
    population_sizes::Vector{Int}
    memory_lengths::Vector{Int}
    error_rates::Vector{Float64}
    starting_conditions::Vector{Tuple{String, UserVariables}} # ("starting_condition_name", UserVariables(var1=>'val1', var2=>'val2'))
    stopping_conditions::Vector{Tuple{String, UserVariables}} # ("stopping_condition_name", UserVariables(var1=>'val1', var2=>'val2'))
    graphmodels::Vector{GraphModelGenerator}
    size::Int
    # function ModelGenerator(
    #     game::Game,
    #     population_sizes::Vector{Int},
    #     memory_lengths::Vector{Int},
    #     error_rates::Vector{Float64},
    #     starting_conditions::Vector{Tuple{String, UserVariables}},
    #     stopping_conditions::Vector{Tuple{String, UserVariables}},
    #     graphmodels::Vector{GraphModelGenerator}
    #     )
    #     sz = sum(Interactions.volume(population_sizes, memory_lengths, error_rates, starting_conditions, stopping_conditions) .* size.(graphmodels))
    #     return new(game, population_sizes, memory_lengths, error_rates, starting_conditions, stopping_conditions, graphmodels, sz)
    # end
end

function ModelGenerator(game::Game,
    population_sizes::Union{Integer, Vector{<:Integer}},
    memory_lengths::Union{Integer, Vector{<:Integer}},
    error_rates::Union{Real, Vector{<:Real}},
    starting_conditions::Union{Tuple{String, UserVariables}, Vector{Tuple{String, UserVariables}}},
    stopping_conditions::Union{Tuple{String, UserVariables}, Vector{Tuple{String, UserVariables}}},
    graphmodels::Union{GraphModelGenerator, Vector{GraphModelGenerator}}
)   
    population_sizes = [population_sizes...]
    memory_lengths = [memory_lengths...]
    error_rates = [error_rates...]
    if starting_conditions isa Tuple{String, UserVariables} starting_conditions = Vector{Tuple{String, UserVariables}}([starting_conditions]) end
    if stopping_conditions isa Tuple{String, UserVariables} stopping_conditions = Vector{Tuple{String, UserVariables}}([stopping_conditions]) end
    graphmodels = if graphmodels isa GraphModelGenerator graphmodels = Vector{GraphModelGenerator}([graphmodels]) end

    println(graphmodels)

    sz = sum(Interactions.volume(population_sizes, memory_lengths, error_rates, starting_conditions, stopping_conditions) .* size.(graphmodels))

    return ModelGenerator(game, population_sizes, memory_lengths, error_rates, starting_conditions, stopping_conditions, graphmodels, sz)
end

# Base.size(generator::ModelGenerator) = getfield(generator, :size) #NOTE: could have one size function for all generators


function generate_model(generator::ModelGenerator, index::Integer) #NOTE: could use iterator method here too, but would be much less efficient
    count = 0
    for population in generator.population_sizes
        for memory_length in generator.memory_lengths
            for error_rate in generator.error_rates
                for starting_condition in generator.starting_conditions
                    for stopping_condition in generator.stopping_conditions
                        params = Parameters(population, memory_length, error_rate, starting_condition[1], stopping_condition[1], user_variables=merge(starting_condition[2], stopping_condition[2]))
                        for graphmodel_generator in generator.graphmodels
                            for graphmodel in graphmodel_generator
                                count += 1
                                if count == index
                                    return Model(generator.game, params, graphmodel)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nothing
end

function generate_database(generator::ModelGenerator)
    for population in generator.population_sizes
        for memory_length in generator.memory_lengths
            for error_rate in generator.error_rates
                for starting_condition in generator.starting_conditions
                    for stopping_condition in generator.stopping_conditions
                        params = Parameters(population, memory_length, error_rate, starting_condition[1], stopping_condition[1], user_variables=merge(starting_condition[2], stopping_condition[2]))
                        for graphmodel_generator in generator.graphmodels
                            for graphmodel in graphmodel_generator
                                model = Model(generator.game, params, graphmodel)
                                Database.db_insert_model(model)
                            end
                        end
                    end
                end
            end
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