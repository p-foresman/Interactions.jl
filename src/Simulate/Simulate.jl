############################### MAIN TRANSITION TIME SIMULATION #######################################

#NOTE: clean this stuff up
module Simulate

export simulate

import
    ..Types,
    ..Database,
    ..Generators,
    ..Interactions

using
    Random,
    Distributed,
    DataStructures,
    TimerOutputs

include("engine.jl")
include("producers.jl")


"""
    simulate(model::Model; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using the model provided.
"""
simulate(model::Types.Model; kwargs...) = simulate_supervisor(model; kwargs..., start_time=time()) #start_time last to overwrite user-given start_time

"""
    simulate(model_id::Int; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using a model stored in the configured database with the given model_id. The model will be reconstructed to be used in the simulation.
Note: a database must be configured to use this method and a model with the given model_id must exist in the configured database.
"""

function simulate(model_id::Integer; kwargs...)
    Database.assert_db()
    model = Database.reconstruct_model(model_id) #construct model associated with id
    return simulate_supervisor(model; kwargs..., start_time=time())
end

function simulate(model::Types.Model, model_id::Int; kwargs...) #NOTE: potentially dangerous method that could screw up database integrity
    @assert !isnothing(Interactions.DATABASE()) Database.NoDatabaseError()
    Database.insert_model(model; model_id=model_id)
    return simulate_supervisor(model; kwargs..., start_time=time())
end

simulate(generator::Generators.ModelGenerator; kwargs...) = simulate_supervisor(generator; kwargs..., start_time=time())

simulate(generator::Generators.ModelGeneratorSet; kwargs...) = simulate_supervisor(generator; kwargs..., start_time=time())

function simulate(simulation_uuid::String; kwargs...)
    Database.assert_db()
    state = Database.reconstruct_simulation(simulation_uuid) #NOTE: model needs to be consumed by state!
    return simulate_supervisor(state; kwargs..., start_time=time())
end

function simulate(;kwargs...) #NOTE: probably don't want this method for simulation continuation
    Database.assert_db()
    simulation_uuids = Database.get_incomplete_simulation_uuids()
    # println(simulation_uuids)
    states = Vector{Types.State}() #NOTE: model needs to be consumed by state!
    for simulation_uuid in simulation_uuids
        push!(states, Database.reconstruct_simulation(simulation_uuid))
    end

    return simulate_supervisor(states; kwargs..., start_time=time())
end


function simulate_supervisor(recipe::Union{Types.Model, Generators.ModelGenerator, Generators.ModelGeneratorSet, Types.State, Vector{Types.State}}; start_time::Float64, samples::Integer=1, db_group_id::Union{Integer, Nothing} = nothing)    
    producer, total_jobs = get_producer(recipe, samples)

    jobs = RemoteChannel(()->Channel{Types.State}(32), 1)
    results = RemoteChannel(()->Channel{Union{Types.State, Exception}}(nworkers()), 1) #allow this to hold Exceptions for error handling
    
    @async producer(jobs)

    for worker in workers() #run a simulate_worker process on each worker
        remote_do(simulate_worker, worker, jobs, results; start_time=start_time, timeout=Interactions.SETTINGS.timeout, capture_interval=Interactions.SETTINGS.capture_interval)
    end

    num_received = 0
    num_completed = 0
    while num_received < total_jobs
        #push to db if the simulation has completed OR if checkpoint is active in settings. For timeout with checkpoint disabled, data is NOT pushed to a database (currently)
        result_state = take!(results)
        isa(result_state, Exception) && throw(result_state) #error handling for distributed workers

        simulation_uuid::Union{String, Nothing} = nothing
        try
            simulation_uuid = Database.insert_simulation(result_state, db_group_id; full_store=!isnothing(Interactions.DATABASE()) ? Interactions.DATABASE().full_store : false) #false doesnt matter here, if there's no database this will return a NoDatabaseError() and nothing will happen
        catch e
            !isa(e, Database.NoDatabaseError) && throw(e)
        end

        if Types.iscomplete(result_state)
            num_received += 1
            num_completed += 1
        elseif Types.istimedout(result_state)
            num_received += 1
        else #if the state is not complete and it didn't time out, it'a a periodic push, so send back to simulate futher
            !isnothing(simulation_uuid) && Types.prev_simulation_uuid!(result_state, simulation_uuid) #set the previously-pushed simulation_uuid to keep order
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


function simulate_worker(jobs::RemoteChannel{Channel{Types.State}}, results::RemoteChannel{Channel{Union{Types.State, Exception}}}; start_time::Float64, timeout::Union{Int, Nothing}=nothing, capture_interval::Union{Int, Nothing}=nothing)
    local state::Types.State
    while true
        try
            state = take!(jobs)
            
            stopping_condition_reached = Types.get_enclosed_stopping_condition_fn(state.model)
            Types.restore_rng_state(state)
            
            simulate!(state, timeout, capture_interval; stopping_condition_reached=stopping_condition_reached, start_time=start_time)
            # @timeit to "simulate!" simulate!(state, timeout, capture_interval; stopping_condition_reached=stopping_condition_reached, start_time=start_time, to=to)

            if Types.iscomplete(state) || Types.istimedout(state)
                println(" --> periods elapsed: $(Types.period(state))")
                flush(stdout)
            end
            put!(results, state)
        catch e
            if isa(e, InvalidStateException) #channel is closed, break out of loop and return function
                break
            else
                put!(results, e)
            end 
        end
    end
    return nothing
end

end #Simulate