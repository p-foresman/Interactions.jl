
"""
    simulate(model::Model; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using the model provided.
"""
simulate(model::Model; kwargs...) = _simulate_distributed_barrier(model, Interactions.DATABASE(); kwargs..., start_time=time()) #start_time last to overwrite user-given start_time

"""
    simulate(model_id::Int; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using a model stored in the configured database with the given model_id. The model will be reconstructed to be used in the simulation.
Note: a database must be configured to use this method and a model with the given model_id must exist in the configured database.
"""
function simulate_aaa(model_id::Integer; kwargs...)
    model = Database.db_reconstruct_model(model_id) #construct model associated with id
    model isa Database.NoDatabaseError && throw(model)
    return _simulate_model_barrier(model, Interactions.DATABASE(); kwargs..., start_time=time())
end

function simulate(model::Model, model_id::Int; kwargs...) #NOTE: potentially dangerous method that could screw up database integrity
    @assert !isnothing(Interactions.DATABASE()) Database.NoDatabaseError()
    return _simulate_model_barrier(model, model_id, Interactions.DATABASE(); start_time=time(), kwargs...)
end

simulate(generator::Generators.ModelGenerator; kwargs...) = _simulate_distributed_barrier(generator, Interactions.DATABASE(); start_time=time(), kwargs...)

function simulate(simulation_uuid::String; kwargs...)
    @assert !isnothing(Interactions.DATABASE()) Database.NoDatabaseError()
    return _simulate_model_barrier(simulation_uuid, Interactions.DATABASE(); start_time=time(), kwargs...)
end

function simulate(;kwargs...) #NOTE: probably don't want this method for simulation continuation
    @assert !isnothing(Interactions.DATABASE()) Database.NoDatabaseError()
    return _simulate_model_barrier(Interactions.DATABASE(); start_time=time(), kwargs...)
end

function get_producer(model::Model, samples::Integer)
    seed::Union{Int, Nothing} = Interactions.SETTINGS.use_seed ? Interactions.SETTINGS.random_seed : nothing
    function producer(channel::Channel)
        model_id = Database.db_insert_model(model)
        state = State(model, random_seed=seed, model_id=model_id isa Database.NoDatabaseError ? nothing : model_id)
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
            state = State(model, random_seed=seed, model_id=model_id isa Database.NoDatabaseError ? nothing : model_id)
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

function _simulate_distributed_barrier(recipe::Union{Model, ModelGenerator, Vector{State}}, db_info::Database.DatabaseSettings; start_time::Float64, samples::Integer=1, db_group_id::Union{Integer, Nothing} = nothing)
    timeout = Interactions.SETTINGS.timeout
    db_push_period = db_info.push_period
    
    producer, total_jobs = get_producer(recipe, samples)

    jobs = RemoteChannel(()->Channel{State}(producer))
    results = RemoteChannel(()->Channel{State}(nworkers()))

    for worker in workers() #run a _simulate process on each worker
        remote_do(_simulate, worker, jobs, results, start_time, timeout, db_push_period)
    end

    num_received = 0
    num_completed = 0
    while num_received < total_jobs
        #push to db if the simulation has completed OR if checkpoint is active in settings. For timeout with checkpoint disabled, data is NOT pushed to a database (currently)
        result_state = take!(results)
        simulation_uuid = Database.db_insert_simulation(result_state, result_state.model_id, db_group_id)
        if Interactions.iscomplete(result_state)
            num_received += 1
            num_completed += 1
        elseif Interactions.istimedout(result_state)
            num_received += 1
        else #if the state is not complete and it didn't time out, it'a a periodic push, so send back to simulate futher
            Interactions.prev_simulation_uuid!(result_state, simulation_uuid) #set the previously-pushed simulation_uuid to keep order
            put!(jobs, result_state)
        end
    end

    if num_completed < num_received #if all simulations aren't completed, exit with checkpoint exit code
        println("TIMED OUT AT $(Interactions.SETTINGS.timeout)")
        !iszero(Interactions.SETTINGS.timeout_exit_code) && exit(Interactions.SETTINGS.timeout_exit_code)
    else
        println("DONE")
    end

    return nothing
end



function _simulate(jobs::RemoteChannel{Channel{State}}, results::RemoteChannel{Channel{State}}; start_time::Float64, timeout::Union{Int, Nothing}=nothing, db_push_period::Union{Int, Nothing}=nothing)

    local state::State
    while true
        try
            state = take!(jobs)
        catch e
            if e.captured.ex isa InvalidStateException #channel is closed, break out of loop and return function
                break
            else
                throw(e)
            end 
        else
            stopping_condition_reached = Interactions.get_enclosed_stopping_condition_fn(state.model)
            Interactions.restore_rng_state(state)

            _simulate!(state, timeout, db_push_period; stopping_condition_reached=stopping_condition_reached, start_time=start_time)

            if Interactions.iscomplete(state) || Interactions.istimedout(state)
                println(" --> periods elapsed: $(period(state))")
                flush(stdout)
            end
            put!(results, state)
        end
    end
    return nothing
end

#state is only mutated within the scope of this function (using multiple dispatch for to optimize main simulation loop)
function _simulate!(state::State, ::Nothing, ::Nothing; stopping_condition_reached::Function)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end

function _simulate!(state::State, timeout::Int, ::Nothing; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Interactions.timedout!(state)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end

function _simulate!(state::State, ::Nothing, db_push_period::Int; stopping_condition_reached::Function)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif iszero(period(state) % db_push_period)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end

function _simulate!(state::State, timeout::Int, db_push_period::Int; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state.model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Interactions.timedout!(state)
            break
        elseif iszero(period(state) % db_push_period)
            break
        end
    end
    Interactions.rng_state!(state) #update state's rng_state
    return nothing
end