function db_init(db_info::SQLiteInfo)
    mkpath(dirname(db_info.filepath)) #create the directory path if it doesn't already exist
    execute_init_db(db_info)

    #shouldnt really need to try multiple times here
    # success = false
    # while !success
    #     try
    #         execute_init_db(db_info)
    #         success = true
    #     catch e
    #         if e isa SQLite.SQLiteException

    #             showerror(stdout, e)
    #             sleep(rand(0.1:0.1:4.0))
    #         else
    #             throw(e)
    #         end
    #     end
    # end
end

tempdirpath(db_filepath::String) = rsplit(db_filepath, ".", limit=2)[1] * "/"



function db_collect_temp(db_info_master::SQLiteInfo, directory_path::String; cleanup_directory::Bool = false, kwargs...)
    contents = readdir(directory_path)
    for item in contents
        item_path = normpath(joinpath(directory_path, item))
        if isfile(item_path)
            db_info_merger = SQLiteInfo("temp", item_path)
            success = false
            while !success
                try
                    execute_merge_temp(db_info_master, db_info_merger; kwargs...)
                    success = true
                catch e
                    if e isa SQLiteException
                        println("An error has been caught in db_collect_temp():")
                        showerror(stdout, e)
                        sleep(rand(0.1:0.1:4.0))
                    else
                        throw(e)
                    end
                end
            end
            println("[$item_path] merged")
            flush(stdout)
        else
            db_collect_temp(db_info_master, item_path, cleanup_directory=cleanup_directory)
        end
    end
    cleanup_directory && rm(directory_path, recursive=true)
    return nothing
end


function db_insert_group(db_info::SQLiteInfo, description::String)
    # println("Inserting from worker ", myid())
    group_id = nothing
    while isnothing(group_id)
        try
            group_id = execute_insert_sim_group(db_info, description)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_group():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end
    return group_id
end

function db_insert_game(db_info::SQLiteInfo, game::Types.Game)
    name = name(game)
    game_str = JSON3.write(game)
    size = JSON3.write(size(game)) #NOTE: why JSON3.write instead of string()

    game_id = nothing
    while isnothing(game_id)
        try
            game_id = execute_insert_game(db_info, name, game_str, size)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_game():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end

    return game_id
end



function sql_dump_graphmodel(graphmodel::GM) where {GM<:Types.GraphModel}
    params = ""
    values = ""
    for param in fieldnames(GM)
        if param != :type
            params *= "$param, "
            values *= "$(getfield(graphmodel, param)), "
        end
    end
    params = string(rstrip(params, [' ', ',']))
    if !isempty(params)
        params = ", " * params
    end
    values = string(rstrip(values, [' ', ',']))
    if !isempty(values)
        values = ", " * values
    end
    return (params, values)
end

function db_insert_graphmodel(db_info::SQLiteInfo, graphmodel::Types.GraphModel)
    model_graphmodel = graphmodel(model)
    graphmodel_name = Types.fn_name(model_graphmodel)
    graphmodel_display = Types.displayname(model_graphmodel)
    graphmodel_params = Types.params(model_graphmodel)
    graphmodel_kwargs = string(model_graphmodel.kwargs)

    # graphmodel_str = JSON3.write(graphmodel)
    # db_params_dict = Dict{Symbol, Any}(:λ => nothing, :β => nothing, :α => nothing, :blocks => nothing, :p_in => nothing, :p_out => nothing) #allows for parameter-based queries
    

    # parameters_str, values_str = sql_dump_graphmodel(graphmodel)

    graphmodel_id = nothing
    while isnothing(graph_id)
        try
            graphmodel_id = execute_insert_graphmodel(db_info, graphmodel_name, graphmodel_display, graphmodel_kwargs, graphmodel_params)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_graphmodel():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end

    return graphmodel_id
end

function db_insert_parameters(db_info::SQLiteInfo, params::Types.Parameters)
    params_json_str = JSON3.write(params)

    parameters_id = nothing
    while isnothing(parameters_id)
        try
            parameters_id = execute_insert_parameters(db_info, params, params_json_str)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_parameters():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end

    return parameters_id
end


function db_insert_model(db_info::SQLiteInfo, model::Types.Model; model_id::Union{Nothing, Integer}=nothing)
    model_game = Types.game(model)
    game_name = Types.displayname(model_game)
    game_str = JSON3.write(model_game)
    game_size = JSON3.write(Types.size(model_game)) #NOTE: why JSON3.write instead of string()

    model_graphmodel = Types.graphmodel(model)
    graphmodel_name = Types.fn_name(model_graphmodel)
    graphmodel_display = Types.displayname(model_graphmodel)
    graphmodel_params = Types.params(model_graphmodel)
    graphmodel_kwargs = string(model_graphmodel.kwargs)
    # model_graphmodel = graphmodel(model)
    # graphmodel_display = displayname(model_graphmodel)
    # graphmodel_type = Types.type(model_graphmodel)
    # graphmodel_str = JSON3.write(model_graphmodel)
    # graphmodel_parameters_str, graphmodel_values_str = sql_dump_graphmodel(model_graphmodel)

    model_params = Types.parameters(model)
    parameters_str = JSON3.write(model_params)

    # model_startingcondition = startingcondition(model)
    # startingcondition_str = JSON3.write(typeof(model_startingcondition)(model_startingcondition)) #generates a "raw" starting condition object for the database
    # startingcondition_type = type(model_startingcondition)

    # model_stoppingcondition = stoppingcondition(model)
    # stoppingcondition_str = JSON3.write(typeof(model_stoppingcondition)(model_stoppingcondition)) #generates a "raw" stopping condition object for the database
    # stoppingcondition_type = type(model_stoppingcondition)

    # adj_matrix_str = Interactions.adjacency_matrix_str(model)


    # println(graphmodel_parameters_str)
    # println(graphmodel_values_str)
    # model_id = nothing
    # while isnothing(model_id)
        # try
    model_id = execute_insert_model(db_info,
                                    game_name, game_str, game_size,
                                    graphmodel_name, graphmodel_display, graphmodel_kwargs, graphmodel_params,
                                    model_params, parameters_str;
                                    # adj_matrix_str;
                                    model_id=model_id)
    #     catch e
    #         if e isa SQLiteException
    #             println("An error has been caught in db_insert_model():")
    #             showerror(stdout, e)
    #             sleep(rand(0.1:0.1:4.0))
    #         else
    #             throw(e)
    #         end
    #     end
    # end

    return model_id
end


function db_insert_simulation(db_info::SQLiteInfo, state::Types.State, model_id::Integer, sim_group_id::Union{Integer, Nothing} = nothing; full_store::Bool=true)
    data_json = "{}"
    if isdefined(Main, :get_data) #NOTE: this is the quick and dirty way to do this. Ideally need to validate that the get_data function takes State and returns Dict{String, Any}(). (probably should pass the function to state)
                                 # this also doesnt allow for multiple get_data functions to be defined! need to make more robust
        data_json = JSON3.write(getfield(Main, :get_data)(state))
    end
    state_bin = full_store ? serialize_to_vec(state) : nothing
    
    simulation_uuid = nothing
    while isnothing(simulation_uuid)
        try
            simulation_uuid = execute_insert_simulation(db_info, model_id, sim_group_id, state.prev_simulation_uuid, Types.period(state), Int(Types.iscomplete(state)), JSON3.write(user_variables(state)), data_json, state_bin)
            #simulation_status = simulation_insert_result.status_message
            # simulation_uuid = simulation_insert_result.simulation_uuid
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_simulation():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end
    return simulation_uuid
end




function db_reconstruct_model(db_info::SQLiteInfo, model_id::Integer)
    df = execute_query_models(db_info, model_id)

    params = JSON3.read(df[1, :parameters], Types.Parameters)
    payoff_matrix_size = JSON3.read(df[1, :payoff_matrix_size], Tuple)
    game = JSON3.read(df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], prod(payoff_matrix_size)})
    graphmodel = JSON3.read(df[1, :graphmodel], Types.GraphModel)
    # regen_graph = Graph(df[1, :graph_adj_matrix])

    model = Model(game, params, graphmodel) #, regen_graph)

    return model
end


function db_reconstruct_simulation(db_info::SQLiteInfo, simulation_uuid::String)
    simulation_df = execute_query_simulations_for_restore(db_info, simulation_uuid)
    @assert !ismissing(simulation_df[1, :state_bin]) "this simulation is not reproducable. 'full_store' was set to 'false' in the config file"
    state = deserialize_from_vec(simulation_df[1, :state_bin])
    return (state.model, state) #NOTE: get rid of model here
end

function db_get_incomplete_simulation_uuids(db_info::SQLiteInfo)
    uuids::Vector{String} = execute_query_incomplete_simulations(db_info)[:, :uuid]
    return uuids
end

function db_has_incomplete_simulations(db_info::SQLiteInfo)
    return !isempty(db_get_incomplete_simulation_uuids(db_info))
end
