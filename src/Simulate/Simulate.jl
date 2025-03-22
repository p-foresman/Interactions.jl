############################### MAIN TRANSITION TIME SIMULATION #######################################

#NOTE: clean this stuff up
module Simulate

export simulate

import
    ..Database

using
    ..Interactions,
    Random,
    Distributed,
    DataStructures

include("simulation_functions.jl")


"""
    simulate(model::Model; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using the model provided.
"""
function simulate(model::Model; db_group_id::Union{Nothing, Integer} = nothing)
    # if !isnothing(SETTINGS.checkpoint) Interactions.SETTINGS.checkpoint.start_time = time() end #fine for now
    return _simulate_model_barrier(model, Interactions.DATABASE(), start_time=time())
    # _simulate_distributed_barrier(model, Interactions.DATABASE(), db_group_id=db_group_id)
end


"""
    simulate(model_id::Int; db_group_id::Union{Nothing, Integer} = nothing)

Run a simulation using a model stored in the configured database with the given model_id. The model will be reconstructed to be used in the simulation.
Note: a database must be configured to use this method and a model with the given model_id must exist in the configured database.
"""
function simulate(model_id::Int; db_group_id::Union{Nothing, Integer} = nothing)
    @assert !isnothing(Interactions.DATABASE()) Database._nodb()

    # timer = Timer(timeout(model, Interactions.DATABASE()))
    return _simulate_model_barrier(model_id, Interactions.DATABASE(), start_time=time())
    # _simulate_distributed_barrier(model, Interactions.DATABASE(), db_group_id=db_group_id)

    # if nworkers() > 1
    #     return _simulate_distributed_barrier(model, Interactions.DATABASE(), db_group_id=db_group_id)
    # else
    #     return _simulate(model, Interactions.DATABASE(), periods_elapsed=periods_elapsed, db_group_id=db_group_id, prev_simulation_uuid=prev_simulation_uuid, distributed_uuid=distributed_uuid)
    # end
end

function simulate(model::Model, model_id::Int; db_group_id::Union{Nothing, Integer} = nothing) #NOTE: potentially dangerous method that could screw up database integrity
    @assert !isnothing(Interactions.DATABASE()) Database._nodb()

    # timer = Timer(timeout(model, Interactions.DATABASE()))
    return _simulate_model_barrier(model, model_id, Interactions.DATABASE(); db_group_id=db_group_id, start_time=time())
    # _simulate_distributed_barrier(model, Interactions.DATABASE(), db_group_id=db_group_id)

    # if nworkers() > 1
    #     return _simulate_distributed_barrier(model, Interactions.DATABASE(), db_group_id=db_group_id)
    # else
    #     return _simulate(model, Interactions.DATABASE(), periods_elapsed=periods_elapsed, db_group_id=db_group_id, prev_simulation_uuid=prev_simulation_uuid, distributed_uuid=distributed_uuid)
    # end
end

function simulate() #NOTE: probably don't want this method for simulation continuation
    @assert !isnothing(Interactions.DATABASE()) Database._nodb()

    return _simulate_model_barrier(Interactions.DATABASE(), start_time=time())
end

function simulate(simulation_uuid::String)
    @assert !isnothing(Interactions.DATABASE()) Database._nodb()

    return _simulate_model_barrier(simulation_uuid, Interactions.DATABASE(), start_time=time())
end

# function simulate(model_list::Vector{<:Model})
#     for model in model_list
#         show(model)
#         flush(stdout)

#         simulate(model, preserve_graph)
#     end
# end


function _simulate_model_barrier(model::Model, ::Nothing; start_time::Float64, kwargs...)
    return _simulate_distributed_barrier(model, start_time=start_time)
end

function _simulate_model_barrier(model::Model, db_info::Database.DatabaseSettings; start_time::Float64, db_group_id::Union{Nothing, Integer} = nothing)
    model_id = Database.db_insert_model(Database.main(db_info), model)
    return _simulate_distributed_barrier(model, db_info; model_id=model_id, db_group_id=db_group_id, start_time=start_time)
end

function _simulate_model_barrier(model_id::Int, db_info::Database.DatabaseSettings; start_time::Float64, db_group_id::Union{Nothing, Integer} = nothing)
    # @assert !isnothing(Interactions.DATABASE()) "Cannot use 'simulate(model_id::Int)' method without a database configured."
    model = Database.db_reconstruct_model(Database.main(db_info), model_id) #construct model associated with id
    return _simulate_distributed_barrier(model, db_info; model_id=model_id, db_group_id=db_group_id, start_time=start_time)
end


function _simulate_model_barrier(model::Model, model_id::Int, db_info::Database.DatabaseSettings; start_time::Float64, db_group_id::Union{Nothing, Integer} = nothing)
    # @assert !isnothing(Interactions.DATABASE()) "Cannot use 'simulate(model_id::Int)' method without a database configured."
    Database.db_insert_model(Database.main(db_info), model; model_id=model_id)
    return _simulate_distributed_barrier(model, db_info; model_id=model_id, db_group_id=db_group_id, start_time=time())
end


function _simulate_model_barrier(db_info::Database.DatabaseSettings; start_time::Float64, db_group_id::Union{Nothing, Integer} = nothing)
    simulation_uuids = Database.db_get_incomplete_simulation_uuids(Database.main(db_info))
    println(simulation_uuids)
    model_state_tuples = Vector{Tuple{Model, State}}()
    for simulation_uuid in simulation_uuids
        push!(model_state_tuples, Database.db_reconstruct_simulation(Database.main(db_info), simulation_uuid))
    end

    return _simulate_distributed_barrier(model_state_tuples, db_info, start_time=start_time, db_group_id=db_group_id)
end

function _simulate_model_barrier(simulation_uuid::String, db_info::Database.DatabaseSettings; start_time::Float64, db_group_id::Union{Nothing, Integer} = nothing)
    model_state::Tuple{Model, State} = Database.db_reconstruct_simulation(Database.main(db_info), simulation_uuid)

    return _simulate_distributed_barrier(model_state, db_info, start_time=start_time, db_group_id=db_group_id)
end


function _simulate_distributed_barrier(model::Model; start_time::Float64, kwargs...) #NOTE: should preserve_graph be in params?
    show(model)
    flush(stdout) #flush buffer   
        
    # states::Vector{State} = @distributed (append!) for process in 1:nworkers() #without reducer, need @sync @distributed ...
    #     print("Process $process of $(nworkers())")
    #     flush(stdout)
    #     # if !preserve_graph
    #     #     state = State(model) #regenerate state so each process has a different graph
    #     # end
    #     [_simulate(model, start_time=start_time)]
    # end
    timeout = Interactions.SETTINGS.timeout
    num_procs = Interactions.SETTINGS.procs #nworkers()
    seed::Union{Int, Nothing} = Interactions.SETTINGS.use_seed ? Interactions.SETTINGS.random_seed : nothing

    stopping_condition_func = Interactions.get_enclosed_stopping_condition_fn(model) #create the stopping condition function to be used in the simulation(s) from the user-defined closure
    result_channel = RemoteChannel(()->Channel{State}(num_procs))

    @distributed for process in 1:num_procs
        print("Process $process of $(num_procs)")
        flush(stdout)
        # if !preserve_graph
        #     state = State(model) #regenerate state so each process has a different graph
        # end
        !isnothing(seed) && Random.seed!(seed)


        _simulate(model, State(model, random_seed=seed), timeout, nothing, stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
    end

    num_received = 0
    num_completed = 0
    result_states = Vector{State}()
    while num_received < num_procs
        #push to db if the simulation has completed OR if checkpoint is active in settings. For timeout with checkpoint disabled, data is NOT pushed to a database (currently)
        result_state = take!(result_channel)
        if Interactions.iscomplete(result_state) num_completed += 1 end
        push!(result_states, result_state)
        num_received += 1
    end

    if num_completed < num_received #if all simulations aren't completed, exit with checkpoint exit code
        println("CHECKPOINT")
        !iszero(SETTINGS.timeout_exit_code) && exit(SETTINGS.timeout_exit_code)
    else
        println("DONE")
    end

    return result_states
end


# function get_result_states(channel::RemoteChannel{Channel{State}}, num_procs::Integer) #NOTE: could probobly remove num_procs (keep for now)
#     num_received = 0
#     num_completed = 0
#     result_states = Vector{State}()
#     while num_received < num_procs
#         #push to db if the simulation has completed OR if checkpoint is active in settings. For timeout with checkpoint disabled, data is NOT pushed to a database (currently)
#         result_state = take!(channel)
#         simulation_uuid = Database.db_insert_simulation(Database.main(db_info), result_state, model_id, db_group_id)
#         if Interactions.iscomplete(result_state)
#             push!(result_states, result_state)
#             num_received += 1
#             num_completed += 1
#         elseif Interactions.istimedout(result_state)
#             push!(result_states, result_state)
#             num_received += 1
#         else #if the state is not complete and it didn't time out, it'a a periodic push, so send back to simulate futher
#             Interactions.prev_simulation_uuid!(result_state, simulation_uuid) #set the previously-pushed simulation_uuid to keep order
#             remote_do(_simulate, default_worker_pool(), model, result_state, db_push_period; stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
#         end
#     end

#     if num_completed < num_received #if all simulations aren't completed, exit with checkpoint exit code
#         println("TIMED OUT AT $(Interactions.SETTINGS.timeout)")
#         !iszero(Interactions.SETTINGS.timeout_exit_code) && exit(Interactions.SETTINGS.timeout_exit_code)
#     else
#         println("DONE")
#     end
#     return result_states
# end

function _simulate_distributed_barrier(model::Model, db_info::Database.DatabaseSettings; model_id::Int, start_time::Float64, db_group_id::Union{Integer, Nothing} = nothing)
    # distributed_uuid = "$(displayname(game(model)))__$(displayname(graphmodel(model)))__$(displayname(parameters(model)))__Start=$(displayname(startingcondition(model)))__Stop=$(displayname(stoppingcondition(model)))__MODELID=$model_id"

    # db_info_list = [db_info]
    # if nworkers() > 1
    #     println("\nSimulation Distributed UUID: $distributed_uuid")
    #     db_info_list = db_init_distributed(distributed_uuid)
    # end

    show(model)
    flush(stdout) #flush buffer


    # states::Vector{State} = @distributed (append!) for (process, db_info) in collect(enumerate(db_info_list))
    #     print("Process $process of $(nworkers())")
    #     flush(stdout)
    #     # if !preserve_graph
    #     #     state = State(model) #regenerate state so each process has a different graph
    #     # end
    #     [_simulate(model, State(model), db_info, model_id=model_id, db_group_id=db_group_id, distributed_uuid=distributed_uuid, start_time=start_time)] #db_id_tuple=db_id_tuple
    # end
    seed::Union{Int, Nothing} = Interactions.SETTINGS.use_seed ? Interactions.SETTINGS.random_seed : nothing
    timeout = Interactions.SETTINGS.timeout
    db_push_period = db_info.push_period

    stopping_condition_func = Interactions.get_enclosed_stopping_condition_fn(model) #create the stopping condition function to be used in the simulation(s)
    
    num_procs = Interactions.SETTINGS.procs #nworkers()
    println("num procs: $num_procs")
    result_channel = RemoteChannel(()->Channel{State}(num_procs))

    #NOTE: try to get rid of this @distributed thing and utilize remote_do() like below?
    @distributed for process in 1:num_procs
        print("Process $process of $(num_procs)")
        flush(stdout)

        # if !preserve_graph
        #     state = State(model) #regenerate state so each process has a different graph
        # end
        !isnothing(seed) && Random.seed!(seed)

        _simulate(model, State(model, random_seed=seed), timeout, db_push_period, stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
    end
    
    num_received = 0
    num_completed = 0
    result_states = Vector{State}()
    # to_push = Queue{State}()
    while num_received < num_procs
        #push to db if the simulation has completed OR if checkpoint is active in settings. For timeout with checkpoint disabled, data is NOT pushed to a database (currently)
        result_state = take!(result_channel)
        # if length(to_push) == 5000
        #     dequeue!(to_push)
        # end
        # enqueue!(to_push, deepcopy(result_state))
        simulation_uuid = Database.db_insert_simulation(result_state, model_id, db_group_id)
        if Interactions.iscomplete(result_state)
            push!(result_states, result_state)
            num_received += 1
            num_completed += 1
        elseif Interactions.istimedout(result_state)
            push!(result_states, result_state)
            num_received += 1
        else #if the state is not complete and it didn't time out, it'a a periodic push, so send back to simulate futher
            Interactions.prev_simulation_uuid!(result_state, simulation_uuid) #set the previously-pushed simulation_uuid to keep order
            remote_do(_simulate, default_worker_pool(), model, result_state, timeout, db_push_period; stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
        end
    end

    # simulation_uuid = ""
    # while !isempty(to_push)
    #     sim = dequeue!(to_push)
    #     !isempty(simulation_uuid) && Interactions.prev_simulation_uuid!(sim, simulation_uuid)
    #     simulation_uuid = Database.db_insert_simulation(sim, model_id, db_group_id)
    # end


    if num_completed < num_received #if all simulations aren't completed, exit with checkpoint exit code
        println("TIMED OUT AT $(Interactions.SETTINGS.timeout)")
        !iszero(Interactions.SETTINGS.timeout_exit_code) && exit(Interactions.SETTINGS.timeout_exit_code)
    else
        println("DONE")
    end

    return result_states
end

function _simulate_distributed_barrier(model_state_tuples::Vector{Tuple{Model, State}}, db_info::Database.DatabaseSettings; start_time::Float64, db_group_id::Union{Integer, Nothing} = nothing)
    # show(model)
    # flush(stdout) #flush buffer
    timeout = Interactions.SETTINGS.timeout
    db_push_period = db_info.push_period

    # stopping_condition_func = Interactions.get_enclosed_stopping_condition_fn(model) #create the stopping condition function to be used in the simulation(s)
    result_channel = RemoteChannel(()->Channel{State}(nworkers()))
    num_incomplete = length(model_state_tuples)
    @distributed for model_state in model_state_tuples
        print("Process $(myid()) of $num_incomplete")
        flush(stdout)
        # if !preserve_graph
        #     state = State(model) #regenerate state so each process has a different graph
        # end
        stopping_condition_func = Interactions.get_enclosed_stopping_condition_fn(model_state[1]) #create the stopping condition function to be used in the simulation(s)
        _simulate(model_state[1], model_state[2], timeout, db_push_period, stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
    end
    

    num_received = 0
    num_completed = 0
    result_states = Vector{State}()
    while num_received < num_incomplete
        #push to db if the simulation has completed OR if checkpoint is active in settings. For timeout with checkpoint disabled, data is NOT pushed to a database (currently)
        result_state = take!(result_channel)
        simulation_uuid = Database.db_insert_simulation(result_state, model_id, db_group_id)
        if Interactions.iscomplete(result_state)
            push!(result_states, result_state)
            num_received += 1
            num_completed += 1
        elseif Interactions.istimedout(result_state)
            push!(result_states, result_state)
            num_received += 1
        else #if the state is not complete and it didn't time out, it'a a periodic push, so send back to simulate futher
            Interactions.prev_simulation_uuid!(result_state, simulation_uuid) #set the previously-pushed simulation_uuid to keep order
            remote_do(_simulate, default_worker_pool(), model, result_state, timeout, db_push_period; stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
        end
    end


    if num_completed < num_received #if all simulations aren't completed, exit with checkpoint exit code
        println("TIMED OUT AT $(Interactions.SETTINGS.timeout)")
        !iszero(Interactions.SETTINGS.timeout_exit_code) && exit(Interactions.SETTINGS.timeout_exit_code)
    else
        println("DONE")
    end

    return result_states
end


#NOTE: this one needs to be cleaned up (this is the case where a single simulation is continued)
function _simulate_distributed_barrier(model_state::Tuple{Model, State}, db_info::Database.SQLiteInfo; start_time::Float64, db_group_id::Union{Integer, Nothing} = nothing)
    # show(model)
    # flush(stdout) #flush buffer
    timeout = Interactions.SETTINGS.timeout
    db_push_period = db_info.push_period
    # stopping_condition_func = Interactions.get_enclosed_stopping_condition_fn(model) #create the stopping condition function to be used in the simulation(s)
    result_channel = RemoteChannel(()->Channel{State}(nworkers()))
        # if !preserve_graph
        #     state = State(model) #regenerate state so each process has a different graph
        # end
    stopping_condition_func = Interactions.get_enclosed_stopping_condition_fn(model_state[1]) #create the stopping condition function to be used in the simulation(s)

    _simulate(model_state[1], model_state[2], timeout, db_push_period, stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
    

    num_received = 0
    num_completed = 0
    result_states = Vector{State}()
    while num_received < 1
        #push to db if the simulation has completed OR if checkpoint is active in settings. For timeout with checkpoint disabled, data is NOT pushed to a database (currently)
        result_state = take!(result_channel)
        simulation_uuid = Database.db_insert_simulation(result_state, model_id, db_group_id)
        if Interactions.iscomplete(result_state)
            push!(result_states, result_state)
            num_received += 1
            num_completed += 1
        elseif Interactions.istimedout(result_state)
            push!(result_states, result_state)
            num_received += 1
        else #if the state is not complete and it didn't time out, it'a a periodic push, so send back to simulate futher
            Interactions.prev_simulation_uuid!(result_state, simulation_uuid) #set the previously-pushed simulation_uuid to keep order
            remote_do(_simulate, default_worker_pool(), model, result_state, timeout, db_push_period; stopping_condition_reached=stopping_condition_func, channel=result_channel, start_time=start_time)
        end
    end


    if num_completed < num_received #if all simulations aren't completed, exit with checkpoint exit code
        println("TIMED OUT AT $(Interactions.SETTINGS.timeout)")
        !iszero(Interactions.SETTINGS.timeout_exit_code) && exit(Interactions.SETTINGS.timeout_exit_code)
    else
        println("DONE")
    end

    return result_states
end


#NOTE: can definitely reduce _simulate functions into one function (use multiple dispatch at a deeper level for timeout and db_push_period)
function _simulate(model::Model, state::State, ::Nothing, ::Nothing; stopping_condition_reached::Function, channel::RemoteChannel{Channel{State}}, start_time::Float64, prev_simulation_uuid::Union{String, Nothing} = nothing)

    #restore the rng state if the simulation is continued
    Interactions.restore_rng_state(state)


    while true
        run_period!(model, state) #NOTE: could put the stopping condition reached function in run_period! and change the state internally
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        end
    end
    # timeout = Interactions.SETTINGS.timeout
    # while !stopping_condition_reached(state)
    #     run_period!(model, state)
    # end

    println(" --> periods elapsed: $(period(state))")
    flush(stdout) #flush buffer\
    # Interactions.complete!(state)
    Interactions.rng_state!(state) #update state's rng_state
    put!(channel, state)

    return nothing
end


function _simulate(model::Model, state::State, timeout::Int, ::Nothing; stopping_condition_reached::Function, channel::RemoteChannel{Channel{State}}, start_time::Float64, prev_simulation_uuid::Union{String, Nothing} = nothing)

    #restore the rng state if the simulation is continued
    Interactions.restore_rng_state(state)

    while true
        run_period!(model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Interactions.timedout!(state)
            break
        end
    end

    # timeout = Interactions.SETTINGS.timeout
    # completed = true
    # while !stopping_condition_reached(state)
    #     run_period!(model, state)
    #     if (time() - start_time) > timeout
    #         completed = false
    #         Interactions.timedout!(state)
    #         break
    #     end
    # end

    println(" --> periods elapsed: $(period(state))")
    flush(stdout) #flush buffer\
    # completed && Interactions.complete!(state)
    Interactions.rng_state!(state) #update state's rng_state
    put!(channel, state)

    return nothing
end

function _simulate(model::Model, state::State, ::Nothing, db_push_period::Int; stopping_condition_reached::Function, channel::RemoteChannel{Channel{State}}, start_time::Float64, prev_simulation_uuid::Union{String, Nothing} = nothing)
    @assert db_push_period > 0 "db_push_period must be > 0"
    #restore the rng state if the simulation is continued
    Interactions.restore_rng_state(state)


    while true
        run_period!(model, state)
        if stopping_condition_reached(state)
            Interactions.complete!(state)
            break
        elseif iszero(period(state) % db_push_period)
            break
        end
    end


    # timeout = Interactions.SETTINGS.timeout
    # completed = true
    # while !stopping_condition_reached(state)
    #     run_period!(model, state)
    #     if iszero(period(state) % db_push_period)
    #         completed = false
    #         break
    #     end
    # end

    if Interactions.iscomplete(state)
        println(" --> periods elapsed: $(period(state))")
        flush(stdout) #flush buffer
    end
    # completed && Interactions.complete!(state)
    Interactions.rng_state!(state) #update state's rng_state
    put!(channel, state)

    return nothing
end

function _simulate(model::Model, state::State, timeout::Int, db_push_period::Int; stopping_condition_reached::Function, channel::RemoteChannel{Channel{State}}, start_time::Float64, prev_simulation_uuid::Union{String, Nothing} = nothing)
    @assert db_push_period > 0 "db_push_period must be > 0"
    #restore the rng state if the simulation is continued
    Interactions.restore_rng_state(state)

    while true
        run_period!(model, state)
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

    # timeout = Interactions.SETTINGS.timeout
    # completed = true
    # while !stopping_condition_reached(state) #NOTE: this currently doesn't push at period 0 and pushes twice at the end when db_push_period is 1!
    #     run_period!(model, state)
    #     if (time() - start_time) > timeout
    #         completed = false
    #         Interactions.timedout!(state)
    #         break
    #     elseif iszero(period(state) % db_push_period)
    #         completed = false
    #         break
    #     end
    # end

    if Interactions.iscomplete(state) || Interactions.istimedout(state)
        println(" --> periods elapsed: $(period(state))")
        flush(stdout) #flush buffer
    end
    # completed && Interactions.complete!(state)
    Interactions.rng_state!(state) #update state's rng_state
    put!(channel, state)

    return nothing
end











############################### simulate with no db ################################

# function simulate(model::Model; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false)
#     if use_seed == true
#         Random.seed!(SETTINGS.random_seed(model))
#     end

#     while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
#         run_period!(model)
#         periods_elapsed += 1
#     end

#     println(" --> periods elapsed: $periods_elapsed")
#     return periods_elapsed
# end

# function simulate_distributed(model::Model; run_count::Integer = 1, use_seed::Bool = false) #NOTE: should preserve_graph be in params?
#     show(model)
#     flush(stdout) #flush buffer

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         flush(stdout)
#         if !preserve_graph
#             model = regenerate_model(model)
#         end
#         simulate(model, use_seed=use_seed)
#     end
# end

# function simulation_iterator(model_list::Vector{<:Model}; run_count::Integer = 1, use_seed::Bool = false)
#     for model in model_list
#         show(model)
#         flush(stdout)

#         @sync @distributed for run in 1:run_count
#             print("Run $run of $run_count")
#             flush(stdout)
#             if !preserve_graph
#                 model = regenerate_model(model)
#             end
#             simulate(model, use_seed=use_seed)
#         end
#     end
# end




################################# simulate with db_filepath and no db_store_period #####################################



# function simulate(model::Model,  db_filepath::String; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_group_id::Union{Nothing, Integer} = nothing, db_id_tuple::Union{Nothing, DatabaseIdTuple} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
#     if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
#         Random.seed!(SETTINGS.random_seed(model))
#     end

#     if db_id_tuple === nothing 
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)
#     end

#     # @timeit to "simulate" begin
#     while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
#         #play a period worth of games
#         # @timeit to "period" runPeriod!(model, to)
#         run_period!(model)
#         periods_elapsed += 1
#     end
#     # end
#     println(" --> periods elapsed: $periods_elapsed")
#     flush(stdout) #flush buffer
#     db_status = Database.db_insert_simulation(db_filepath, db_group_id, prev_simulation_uuid, db_id_tuple, agentgraph(model), periods_elapsed, distributed_uuid)
#     return (periods_elapsed, db_status)
# end


# function simulate_distributed(model::Model, db_filepath::String; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing)
#     distributed_uuid = "$(displayname(game(model)))__$(displayname(graphmodel(model)))__$(displayname(parameters(model)))__Start=$(displayname(startingcondition(model)))__Stop=$(displayname(stoppingcondition(model)))__MODELID=$model_id"

#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#     show(model)
#     flush(stdout) #flush buffer

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         flush(stdout)
#         if !preserve_graph
#             model = regenerate_model(model)
#         end
#         simulate(model, db_filepath, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end


# function simulation_iterator(model_list::Vector{<:Model}, db_filepath::String; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing)
#     distributed_uuid = "$(uuid4())"

#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     for model in model_list
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#         show(model)
#         flush(stdout) #flush buffer

#         @sync @distributed for run in 1:run_count
#             print("Run $run of $run_count")
#             flush(stdout)
#             if !preserve_graph
#                 model = regenerate_model(model)
#             end
#             simulate(model, db_filepath, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#         end
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end





# ################################ simulate with db_filepath and db_store_period ##################################

# function simulate(model::Model, db_filepath::String, db_store_period::Integer; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_group_id::Union{Nothing, Integer} = nothing, db_id_tuple::Union{Nothing, DatabaseIdTuple} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
#     if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
#         Random.seed!(SETTINGS.random_seed(model))
#     end

#     if db_id_tuple === nothing 
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)
#     end

#     # @timeit to "simulate" begin
#     db_status = nothing #NOTE: THIS SHOULD BE TYPED
#     already_pushed::Bool = false #for the special case that simulation data is pushed to the db periodically and one of these pushes happens to fall on the last period of the simulation
#     while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
#         #play a period worth of games
#         # @timeit to "period" runPeriod!(model, to)
#         run_period!(model)
#         periods_elapsed += 1
#         already_pushed = false
#         if periods_elapsed % db_store_period == 0 #push incremental results to DB
#             db_status = Database.db_insert_simulation(db_filepath, db_group_id, prev_simulation_uuid, db_id_tuple, agentgraph(model), periods_elapsed, distributed_uuid)
#             prev_simulation_uuid = db_status.simulation_uuid
#             already_pushed = true
#         end
#     end
#     # end
#     println(" --> periods elapsed: $periods_elapsed")
#     flush(stdout) #flush buffer
#     if already_pushed == false #push final results to DB at filepath
#         db_status = Database.db_insert_simulation(db_filepath, db_group_id, prev_simulation_uuid, db_id_tuple, agentgraph(model), periods_elapsed, distributed_uuid)
#     end
#     return (periods_elapsed, db_status)
# end


# function simulate_distributed(model::Model, db_filepath::String, db_store_period::Integer; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing)
#     distributed_uuid = "$(displayname(game(model)))__$(displayname(graphmodel(model)))__$(displayname(parameters(model)))__Start=$(displayname(startingcondition(model)))__Stop=$(displayname(stoppingcondition(model)))__MODELID=$model_id"

    
#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#     show(model)
#     flush(stdout) #flush buffer

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         flush(stdout)
#         if !preserve_graph
#             model = regenerate_model(model)
#         end
#         simulate(model, db_filepath, db_store_period, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end


# function simulation_iterator(model_list::Vector{<:Model}, db_filepath::String, db_store_period::Integer; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing)
#     distributed_uuid = "$(uuid4())"

#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     for model in model_list
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#         show(model)
#         flush(stdout) #flush buffer

#         @sync @distributed for run in 1:run_count
#             print("Run $run of $run_count")
#             flush(stdout)
#             if !preserve_graph
#                 model = regenerate_model(model)
#             end
#             simulate(model, db_filepath, db_store_period, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#         end
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end



# # #NOTE: use MVectors for size validation! (params_list_array length should be the same as db_group_id_list length)
# # function distributedSimulationIterator(model_list::Vector{Model}; run_count::Integer = 1, use_seed::Bool = false, db_filepath::String, db_store_period::Union{Integer, Nothing} = nothing, db_group_id::Integer)
# #     slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])

# #     if length(model_list) != parse(Int64, ENV["SLURM_ARRAY_TASK_COUNT"])
# #         throw(ErrorException("Slurm array task count and number of models in the model list differ.\nSLURM_ARRAY_TASK_COUNT: $(parse(Int64, ENV["SLURM_ARRAY_TASK_COUNT"]))\nNumber of models: $(length(model_list))"))
# #     end

# #     model = model_list[slurm_task_id]
     
# #     println("\n\n\n")
# #     println(displayname(model.graphmodel))
# #     println(displayname(model.params))
# #     flush(stdout) #flush buffer

# #     distributed_uuid = "$(displayname(graphmodel))__$(displayname(params))_MODELID=$slurm_task_id"
# #     db_init_distributed(distributed_uuid)

# #     db_id_tuple = (
# #                    game_id = pushGameToDB(db_filepath, model.game),
# #                    graph_id = pushGraphToDB(db_filepath, model.graphmodel),
# #                    params_id = pushParametersToDB(db_filepath, model.params, use_seed),
# #                    starting_condition_id = pushStartingConditionToDB(db_filepath, model.startingcondition),
# #                    stopping_condition_id = pushStoppingConditionToDB(db_filepath, model.startingcondition)
# #                   )

# #     @sync @distributed for run in 1:run_count
# #         print("Run $run of $run_count")
# #         simulate(model, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
# #     end

# #     if nworkers() > 1
# #         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
# #     end
# # end



# # #NOTE: use MVectors for size validation! (params_list_array length should be the same as db_group_id_list length)
# # function distributedSimulationIterator(game::Game, params_list::Vector{Parameters}, graph_params_list::Vector{<:GraphParams}, startingcondition::StartingCondition, stoppingcondition::StoppingCondition; run_count::Integer = 1, use_seed::Bool = false, db_filepath::String, db_store_period::Union{Integer, Nothing} = nothing, db_group_id::Integer)
# #     slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
# #     graph_count = length(graph_params_list)
# #     # params_count = length(params_list)
# #     # slurm_array_length = graph_count * params_count
# #     graph_index = (slurm_task_id % graph_count) == 0 ? graph_count : slurm_task_id % graph_count
# #     graphmodel = graph_params_list[graph_index]
# #     # params_index = (slurm_task_id % params_count) == 0 ? params_count : slurm_task_id % params_count
# #     params_index = ceil(Int64, slurm_task_id / graph_count) #allows for iteration of graphmodel over each sim_param
# #     params = params_list[params_index]
     
# #     println("\n\n\n")
# #     println(displayname(graphmodel))
# #     println(displayname(params))
# #     flush(stdout) #flush buffer

# #     distributed_uuid = "$(displayname(graphmodel))__$(displayname(params))_MODELID=$slurm_task_id"
# #     db_init_distributed(distributed_uuid)

# #     db_game_id = db_filepath !== nothing ? pushGameToDB(db_filepath, game) : nothing
# #     db_graph_id = db_filepath !== nothing ? pushGraphToDB(db_filepath, graphmodel) : nothing
# #     db_params_id = db_filepath !== nothing ? pushParametersToDB(db_filepath, params, use_seed) : nothing

# #     @sync @distributed for run in 1:run_count
# #         print("Run $run of $run_count")
# #         simulate(game, params, graphmodel, startingcondition, stoppingcondition, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_group_id=db_group_id, db_game_id=db_game_id, db_graph_id=db_graph_id, db_params_id=db_params_id, distributed_uuid=distributed_uuid)
# #     end

# #     if db_filepath !== nothing && nworkers() > 1
# #         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
# #     end
# # end



# #used to continue a simulation
# # function simGroupIterator(db_group_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Int = 0)
# #     simulation_ids_df = querySimulationIDsByGroup(db_filepath, db_group_id)
# #     for row in eachrow(simulation_ids_df)
# #         continueSimulation(row[:simulation_id], db_store=db_store, db_filepath=db_filepath, db_store_period=db_store_period)
# #     end
# # end


# # function continueSimulation(db_simulation_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Integer = 0)
# #     prev_sim = db_restore_model(db_filepath, db_simulation_id)
# #     sim_results = simulateTransitionTime(prev_sim.game, prev_sim.params, prev_sim.graphmodel, use_seed=prev_sim.use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_group_id=prev_sim.sim_group_id, prev_simulation_uuid=prev_sim.prev_simulation_uuid)
# # end

end #Simulate