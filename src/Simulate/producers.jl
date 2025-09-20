function get_producer(model::Types.Model, samples::Integer)
    seed::Union{Int, Nothing} = Interactions.SETTINGS.use_seed ? Interactions.SETTINGS.random_seed : nothing
    function producer(channel::Channel)
        model_id::Union{Integer, Nothing} = nothing
        try
            model_id = Database.insert_model(model)
        catch e
            !isa(e, Database.NoDatabaseError) && throw(e)
        end
        for _ in 1:samples
            put!(channel, Types.State(model; random_seed=seed, model_id=model_id))
        end
    end
    return (producer, samples)
end

function get_producer(generator::Union{Generators.ModelGenerator, Generators.ModelGeneratorSet}, samples::Integer)
    seed::Union{Int, Nothing} = Interactions.SETTINGS.use_seed ? Interactions.SETTINGS.random_seed : nothing
    function producer(channel::Channel)
        for model in generator
            model_id::Union{Integer, Nothing} = nothing
            try
                model_id = Database.insert_model(model)
            catch e
                !isa(e, Database.NoDatabaseError) && throw(e)
            end
            for _ in 1:samples
                put!(channel, Types.State(model; random_seed=seed, model_id=model_id))
            end
        end
    end
    return (producer, generator.size * samples)
end

function get_producer(state::Types.State, samples::Integer)
    function producer(channel::Channel)
        for _ in 1:samples
            put!(channel, state)
        end
    end
    return (producer, samples)
end

function get_producer(states::Vector{Types.State}, samples::Integer)
    function producer(channel::Channel)
        for s in states
            for _ in 1:samples
                put!(channel, s)
            end
        end
    end
    return (producer, length(states) * samples)
end