function get_producer(model::Model, samples::Integer)
    seed::Union{Int, Nothing} = Interactions.SETTINGS.use_seed ? Interactions.SETTINGS.random_seed : nothing
    function producer(channel::Channel)
        model_id = Database.db_insert_model(model)
        state = State(model, random_seed=seed, model_id=isa(model_id, Database.NoDatabaseError) ? nothing : model_id)
        for _ in 1:samples

            put!(channel, state)
        end
    end
    return (producer, samples)
end

function get_producer(generator::ModelGenerator, samples::Integer)
    seed::Union{Int, Nothing} = Interactions.SETTINGS.use_seed ? Interactions.SETTINGS.random_seed : nothing
    function producer(channel::Channel)
        for model in generator
            show(model)
            model_id = Database.db_insert_model(model)
            state = State(model, random_seed=seed, model_id=isa(model_id, Database.NoDatabaseError) ? nothing : model_id)
            #Database.db_insert_simulation(state, model_id, db_group_id) #insert initial state if db_push_period!
            for _ in 1:samples
                put!(channel, state)
            end
        end
    end
    return (producer, generator.size * samples)
end

function get_producer(states::Vector{State}, samples::Integer)
    function producer(channel::Channel)
        for state in states
            for _ in 1:samples
                put!(channel, state)
            end
        end
    end
    return (producer, length(states) * samples)
end