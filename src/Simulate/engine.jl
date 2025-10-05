
############################### FUNCTIONS #######################################

# function simulate(state::Types.State, args...; kwargs...) #NOTE: should include this to call simply

#state is only mutated within the scope of this function (using multiple dispatch for to optimize main simulation loop)
function simulate!(state::Types.State, ::Nothing, ::Nothing; stopping_condition_reached::Function, kwargs...)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::Types.State, timeout::Int, ::Nothing; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Types.timedout!(state)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::Types.State, ::Nothing, capture_interval::Int; stopping_condition_reached::Function, kwargs...)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        elseif iszero(Types.period(state) % capture_interval)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end

function simulate!(state::Types.State, timeout::Int, capture_interval::Int; stopping_condition_reached::Function, start_time::Float64)
    while true
        run_period!(state)
        if stopping_condition_reached(state)
            Types.complete!(state)
            break
        elseif (time() - start_time) > timeout
            Types.timedout!(state)
            break
        elseif iszero(Types.period(state) % capture_interval)
            break
        end
    end
    Types.rng_state!(state) #update state's rng_state
    return nothing
end



######################## game algorithm ####################
function run_period!(state::Types.State)
    for component in Types.components(state) #each connected component plays its own period's worth of matches
        # mpp = matches_per_period(num_vertices(component)) * edge_density(num_vertices(component), λ(graph_parameters(model))) #NOTE: CHANGE THIS BACK
        # for _ in 1:Int(ceil(mpp))
        for _ in 1:Types.matches_per_period(component)
            Types.reset_arrays!(state)
            Types.set_players!(state, component)
            # play_game!(state)
            Types.interaction_fn_call(state) # inject user-defined interaction function here
            # @timeit to "reset_arrays!" Types.reset_arrays!(state)
            # @timeit to "set_players!" Types.set_players!(state, component)
            # @timeit to "play_game!" play_game!(state; to=to)
        end
    end
    Types.increment_period!(state)
    return nothing
end