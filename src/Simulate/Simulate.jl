############################### MAIN TRANSITION TIME SIMULATION #######################################

#NOTE: clean this stuff up
module Simulate

export simulate

import
    ..Database,
    ..Generators

using
    ..Interactions,
    Random,
    Distributed,
    DataStructures

include("engine.jl")
include("producers.jl")


"""
    simulate(model::Model; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using the model provided.
"""
simulate(model::Model; kwargs...) = simulate_supervisor(model, Interactions.DATABASE(); kwargs..., start_time=time()) #start_time last to overwrite user-given start_time

"""
    simulate(model_id::Int; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using a model stored in the configured database with the given model_id. The model will be reconstructed to be used in the simulation.
Note: a database must be configured to use this method and a model with the given model_id must exist in the configured database.
"""

function simulate(model_id::Integer; kwargs...)
    Database.assert_db()
    model = Database.db_reconstruct_model(model_id) #construct model associated with id
    return simulate_supervisor(model, Interactions.DATABASE(); kwargs..., start_time=time())
end

function simulate(model::Model, model_id::Int; kwargs...) #NOTE: potentially dangerous method that could screw up database integrity
    @assert !isnothing(Interactions.DATABASE()) Database.NoDatabaseError()
    Database.db_insert_model(model; model_id=model_id)
    return simulate_supervisor(model, Interactions.DATABASE(); kwargs..., start_time=time())
end

simulate(generator::Generators.ModelGenerator; kwargs...) = simulate_supervisor(generator, Interactions.DATABASE(); kwargs..., start_time=time())

simulate(generator::Generators.ModelGeneratorSet; kwargs...) = simulate_supervisor(generator, Interactions.DATABASE(); kwargs..., start_time=time())

function simulate(simulation_uuid::String; kwargs...)
    Database.assert_db()
    model_state::Tuple{Model, State} = Database.db_reconstruct_simulation(simulation_uuid) #NOTE: model needs to be consumed by state!
    return simulate_supervisor(model_state, Interactions.DATABASE(); kwargs..., start_time=time())
end

function simulate(;kwargs...) #NOTE: probably don't want this method for simulation continuation
    Database.assert_db()
    simulation_uuids = Database.db_get_incomplete_simulation_uuids()
    # println(simulation_uuids)
    model_state_tuples = Vector{Tuple{Model, State}}()
    for simulation_uuid in simulation_uuids
        push!(model_state_tuples, Database.db_reconstruct_simulation(simulation_uuid))
    end

    return simulate_supervisor(model_state_tuples, Interactions.DATABASE(); kwargs..., start_time=time())
end



function simulate_supervisor(recipe::Union{Model, Generators.ModelGenerator, Generators.ModelGeneratorSet, Vector{State}}, db_info::Database.DatabaseSettings; start_time::Float64, samples::Integer=1, db_group_id::Union{Integer, Nothing} = nothing)
    timeout = Interactions.SETTINGS.timeout
    db_push_period = db_info.push_period
    
    producer, total_jobs = get_producer(recipe, samples)

    jobs = RemoteChannel(()->Channel{State}(producer))
    results = RemoteChannel(()->Channel{State}(nworkers()))

    for worker in workers() #run a _simulate process on each worker
        remote_do(simulate_worker, worker, jobs, results, start_time, timeout, db_push_period)
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
            !isa(simulation_uuid, Database.NoDatabaseError) && Interactions.prev_simulation_uuid!(result_state, simulation_uuid) #set the previously-pushed simulation_uuid to keep order
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


function simulate_worker(jobs::RemoteChannel{Channel{State}}, results::RemoteChannel{Channel{State}}; start_time::Float64, timeout::Union{Int, Nothing}=nothing, db_push_period::Union{Int, Nothing}=nothing)

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

            simulate!(state, timeout, db_push_period; stopping_condition_reached=stopping_condition_reached, start_time=start_time)

            if Interactions.iscomplete(state) || Interactions.istimedout(state)
                println(" --> periods elapsed: $(period(state))")
                flush(stdout)
            end
            put!(results, state)
        end
    end
    return nothing
end

end #Simulate