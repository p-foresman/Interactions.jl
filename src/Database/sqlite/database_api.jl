using SQLite

const SQLiteDB = SQLite.DB

load_sql_file(::SQLiteInfo, file) = load_sql_file("sqlite", file)

function DB(db_info::SQLiteInfo; busy_timeout::Int=3000)
    db = SQLiteDB(db_info.filepath)
    SQLite.busy_timeout(db, busy_timeout)
    return db
end
begin_transaction(db::SQLiteDB) = SQLite.transaction(db) #does have a default mode that may be useful to change
execute(db::SQLiteDB, sql::SQL) = DBInterface.execute(db, sql)
execute(db::SQLiteDB, sql::SQL, params) = DBInterface.execute(db, sql, params)
query(db::SQLiteDB, sql::SQL) = DataFrame(execute(db, sql))
query(db::SQLiteDB, sql::SQL, params) = DataFrame(execute(db, sql, params))
commit_transaction(db::SQLiteDB) = SQLite.commit(db)
close(db::SQLiteDB) = SQLite.close(db)


"""
    execute(filepath::String, sql::SQL)

Execute SQL on an sqlite database file specified by filepath.
"""
function execute(filepath::String, sql::SQL)
    db = DB(SQLiteInfo("temp", filepath))
    result = execute(db, sql)
    close(db)
    return result
end

"""
    execute(db_info::SQLiteInfo, sql::SQL)

Execute SQL on an sqlite database provided in an SQLiteInfo instance.
"""
function execute(db_info::SQLiteInfo, sql::SQL)    
    db = DB(db_info)
    query = execute(db, sql)
    close(db)
    return query
end


"""
    query(db_info::SQLiteInfo, sql::SQL)

Query the sqlite database provided in an SQLiteInfo instance with the sql (String) provided. Returns a DataFrame containing results.
"""
function query(db_info::SQLiteInfo, sql::SQL)                                                  
    db = DB(db_info)
    query = query(db, sql)
    close(db)
    return query
end

function query(db_info::SQLiteInfo, sql::SQL, params)                                                  
    db = DB(db_info)
    query = query(db, sql, params)
    close(db)
    return query
end

function query(query_dbs::Vector{SQLiteInfo}, sql::SQL)
    @assert !isempty(query_dbs) "query_dbs Vector is empty"                                                           
    db = DB(first(query_dbs))
    for query_db in query_dbs[2:end]
        execute(db, "ATTACH DATABASE '$(query_db.filepath)' as $(query_db.name);")
    end
    query = query(db, sql)
    for query_db in query_dbs[2:end]
        execute(db, "DETACH DATABASE $(query_db.name);")
    end
    close(db)
    return query
end

query(db_info::DatabaseSettings{SQLiteInfo}, sql::SQL) = query([main(db_info), attached(db_info)...], sql)


"""
    query(filepath::String, sql::SQL)

Quick method to query an sqlite database file specified by filepath. Returns a DataFrame containing results.
"""
query(filepath::String, sql::SQL) = query(SQLiteInfo("temp", filepath), sql)

"""
    query(db_info::SQLiteInfo, qp::QueryParams)

Query the sqlite database provided in an SQLiteInfo instance with the <:QueryParams instance provided. Returns a DataFrame containing results.
"""
query(db_info::Union{SQLiteInfo, Vector{SQLiteInfo}, DatabaseSettings{SQLiteInfo}}, qp::QueryParams) = query(db_info, sql(db_info, qp))


"""
    query(db_info::SQLiteInfo, qp::Query_simulations)

Query the sqlite database provided in an SQLiteInfo instance with the Query_simulations instance provided. Will throw an error if the database contains insufficient samples for any requested models. Returns a DataFrame containing results.
"""
function query(db_info::Union{SQLiteInfo, Vector{SQLiteInfo}, DatabaseSettings{SQLiteInfo}}, qp::Query_simulations; ensure_samples::Bool=true)      
    query = query(db_info, sql(db_info, qp))
    ensure_samples && _ensure_samples(query, qp)
    return query
end


function init(db::SQLiteDB)
    mkpath(dirname(db_info.filepath)) #create the directory path if it doesn't already exist

    begin_transaction(db)
    execute(db, load_sql_file("sqlite/sql/games/init.sql"))
    execute(db, load_sql_file("sqlite/sql/graphmodels/init.sql"))
    execute(db, load_sql_file("sqlite/sql/graphmodels/graphmodel_parameters/init.sql"))
    execute(db, load_sql_file("sqlite/sql/models/init.sql"))
    execute(db, load_sql_file("sqlite/sql/models/model_parameters/init.sql"))
    execute(db, load_sql_file("sqlite/sql/groups/init.sql"))
    execute(db, load_sql_file("sqlite/sql/simulations/init.sql"))
    commit_transaction(db)
end

function init(db_info::SQLiteInfo)
    db = DB(db_info)
    init(db)
    close(db)
end


#NOTE: can probably reduce each to one function (don't need a funtion for SQLiteDB and SQLiteInfo)
function insert_game(db::SQLiteDB, game::Types.Game)
    id::Int = query(db, load_sql_file("sqlite/sql/games/insert.sql"), (name(game), string(size(game)), Types.interaction_fn_name(game), serialize_to_vec(game)))[1, :id]
    return id
end

function insert_game(db_info::SQLiteInfo, game::Types.Game)
    db = DB(db_info)
    id = insert_game(db, game)
    close(db)
    return id
end


function insert_graphmodel(db::SQLiteDB, graphmodel::Types.GraphModel)
    begin_transaction(db)
    
    #insert graphmodel
    graphmodel_id::Int = query(db, load_sql_file("sqlite/sql/graphmodels/insert.sql"), (Types.fn_name(graphmodel), Types.displayname(graphmodel), serialize_to_vec(graphmodel)))[1, :id]
    
    #insert each graphmodel parameter referencing the previously inserted graphmodel
    for (param, val) in pairs(Types.parameters(graphmodel))
        execute(db, load_sql_file("sqlite/sql/graphmodels/graphmodel_parameters/insert.sql"), (graphmodel_id, string(param), string(typeof(val)), string(val)))
    end

    commit_transaction(db)
    return id
end

function insert_graphmodel(db_info::SQLiteInfo, graphmodel::Types.GraphModel)
    db = DB(db_info)
    id = insert_graphmodel(db, graphmodel)
    close(db)
    return id
end

function insert_model(db::SQLiteDB, model::Types.Model; model_id::Union{Nothing, Integer}=nothing)
    begin_transaction(db)

    #insert game
    game_id = insert_game(db, Types.game(model))

    #insert graphmodel
    graphmodel_id = insert_graphmodel(db, Types.graphmodel(model))

    #insert model referencing game and graphmodel
    model_id::Int = query(db,
        load_sql_file("sqlite/sql/models/insert.sql"),
        (
            model_id,
            string(Types.agent_type(model)),
            Types.population_size(model),
            game_id,
            graphmodel_id,
            Types.starting_condition_fn_name(model),
            Types.stopping_condition_fn_name(model),
            serialize_to_vec(model)
        )
    )[1, :id]

    #insert each model parameter referencing the previously inserted model
    for (param, val) in pairs(Types.parameters(model))
        execute(db, load_sql_file("sqlite/sql/models/model_parameters/insert.sql"), (model_id, string(param), string(typeof(val)), string(val)))
    end

    commit_transaction(db)
    return model_id
end

function insert_model(db_info::SQLiteInfo, model::Types.Model; kwargs...)
    db = DB(db_info)
    id = insert_model(db, model; kwargs...)
    close(db)
    return id
end





function insert_group(db_info::SQLiteInfo, description::String)
    id::Int = query(db_info, load_sql_file("sqlite/sql/groups/insert.sql"))[1, :id]
    return id
end

function insert_group(db_info::SQLiteInfo, description::String)
    db = DB(db_info)
    id = insert_group(db, description)
    close(db)
    return id
end


function insert_simulation(db::SQLiteDB, state::Types.State, model_id::Integer, group_id::Union{Integer, Nothing} = nothing; full_store::Bool=true)
    data_json = "{}"
    if isdefined(Main, :get_data) #NOTE: this is the quick and dirty way to do this. Ideally need to validate that the get_data function takes State and returns Dict{String, Any}(). (probably should pass the function to state)
                                 # this also doesnt allow for multiple get_data functions to be defined! need to make more robust
        data_json = JSON3.write(getfield(Main, :get_data)(state))
    end
    state_bin = full_store ? serialize_to_vec(state) : nothing

    begin_transaction(db)
    simulation_uuid::String = execute(db,
        load_sql_file("sqlite/sql/simulations/insert.sql"),
        (
            string(uuid4()),
            group_id,
            state.prev_simulation_uuid,
            state.model_id,
            Types.period(state),
            Types.iscomplete(state),
            Types.istimedout(state),
            data_json,
            state_bin
        )
    )[1, :uuid]
    commit_transaction(db)

    return simulation_uuid
end

function insert_simulation(db_info::SQLiteInfo, state::Types.State, model_id::Integer, group_id::Union{Integer, Nothing} = nothing; full_store::Bool=true) #state_bin will be nothing if store_state=false in config
    db = DB(db_info)
    insert_simulation(db, state, model_id, group_id; full_store=full_store)
    close(db)
    return uuid
end






query_models(db::SQLiteDB, id::Integer) = query(db, load_sql_file("sqlite/sql/models/find.sql"), (id))

function query_models(db_info::SQLiteInfo, id::Integer)
    db = DB(db_info)
    results = query_models(db, id)
    close(db)
    return results
end

function reconstruct_model(db_info::SQLiteInfo, model_id::Integer)
    results = query_models(db_info, model_id)
    if isempty(results)
        throw(NotFoundError())
    end
    model::Types.Model = deserialize_from_vec(results[1, :model_bin])
    return model
end


query_simulations(db::SQLiteDB, uuid::String) = query(db, load_sql_file("sqlite/sql/simulations/find.sql", (uuid)))

function query_simulations(db_info::SQLiteInfo, uuid::String)
    db = DB(db_info)
    results = query_simulations(db, uuid)
    close(db)
    return results
end

query_simulations_with_bin(db::SQLiteDB, uuid::String) = query(db, load_sql_file("sqlite/sql/simulations/find_with_bin.sql", (uuid)))

function query_simulations_with_bin(db_info::SQLiteInfo, uuid::String)
    db = DB(db_info)
    results = query_simulations_with_bin(db, uuid)
    close(db)
    return results
end

function reconstruct_simulation(db_info::SQLiteInfo, simulation_uuid::String)
    results = query_simulations_with_bin(db_info, simulation_uuid)
    if isempty(results)
        throw(NotFoundError())
    elseif ismissing(results[1, :state_bin])
        throw("This simulation is not reproducable. 'full_store' was set to 'false' in the config file")
    end
    state::Types.State = deserialize_from_vec(results[1, :state_bin])
    return state
end


query_simulations_incomplete(db::SQLiteDB) = query(db, load_sql_file("sqlite/sql/simulations/find_incomplete.sql"))

function query_simulations_incomplete(db_info::SQLiteInfo)
    db = DB(db_info)
    query = query_simulations_incomplete(db)
    close(db)
    return query
end

function get_incomplete_simulation_uuids(db_info::SQLiteInfo)
    uuids::Vector{String} = query_simulations_incomplete(db_info)[:, :uuid]
    return uuids
end

function has_incomplete_simulations(db_info::SQLiteInfo)
    return !isempty(get_incomplete_simulation_uuids(db_info))
end


query_timeseries(db::SQLiteDB, simulation_uuid::String, limit::Int) = query(db, load_sql_file("sqlite/sql/simulations/timeseries.sql"), (limit, simulation_uuid))
query_timeseries(db_info::SQLiteInfo, simulation_uuid::String, limit::Int) = query(db_info, load_sql_file("sqlite/sql/simulations/timeseries.sql"), (limit, simulation_uuid))
query_timeseries(db_info::Vector{SQLiteInfo}, simulation_uuid::String, limit::Int) = query(db_info, load_sql_file("sqlite/sql/simulations/timeseries.sql"), (limit, simulation_uuid))
query_timeseries(db_info::DatabaseSettings{SQLiteInfo}, simulation_uuid::String, limit::Int) = query(db_info, load_sql_file("sqlite/sql/simulations/timeseries.sql"), (limit, simulation_uuid))




function merge_simulations(db::SQLiteInfo, db_merger_filepath::String; collect_state::Bool=true)
    execute(db, "ATTACH DATABASE '$(db_merger_filepath)' as merge_db;")

    if collect_state
        exectute(db, load_sql_file("sqlite/sql/simulations/merge.sql"))
    else
        exectute(db, load_sql_file("sqlite/sql/simulations/merge_no_bin.sql"))
    end

    execute(db, "DETACH DATABASE merge_db;")
end

function merge_simulations(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo; kwargs...)
    db = DB(db_info_master)
    merge_simulations(db, db_info_merger.filepath; kwargs...)
    close(db)
    return nothing
end



#NOTE: update
function collect_simulations(db_info_master::SQLiteInfo, directory_path::String; cleanup_directory::Bool = false, kwargs...)
    contents = readdir(directory_path)
    for item in contents
        item_path = normpath(joinpath(directory_path, item))
        if isfile(item_path)
            db_info_merger = SQLiteInfo("temp", item_path)
            success = false
            while !success
                try
                    merge_simulations(db_info_master, db_info_merger; kwargs...)
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
            collect_simulations(db_info_master, item_path, cleanup_directory=cleanup_directory)
        end
    end
    cleanup_directory && rm(directory_path, recursive=true)
    return nothing
end


# #NOTE: update
# function merge_full(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo)
#     db = DB(db_info_master)
#     db = DB(db_info; busy_timeout=5000)
#     execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")
#     execute(db, "INSERT OR IGNORE INTO games(game_name, game_bin, payoff_matrix_size) SELECT game_name, game_bin, payoff_matrix_size FROM merge_db.games;")
#     execute(db, "INSERT OR IGNORE INTO graphmodels(graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out) SELECT graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out FROM merge_db.graphmodels;")
#     execute(db, "INSERT OR IGNORE INTO parameters(number_agents, memory_length, error, parameters) SELECT number_agents, memory_length, error, parameters FROM merge_db.parameters;")
#     execute(db, "INSERT OR IGNORE INTO starting_conditions(name, starting_condition) SELECT name, starting_condition FROM merge_db.starting_conditions;")
#     execute(db, "INSERT OR IGNORE INTO stopping_conditions(name, stopping_condition) SELECT name, stopping_condition FROM merge_db.stopping_conditions;")
#     execute(db, "INSERT OR IGNORE INTO sim_groups(description) SELECT description FROM merge_db.sim_groups;")
#     execute(db, "INSERT INTO simulations(simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, parameters_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, period) SELECT simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, parameters_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, period FROM merge_db.simulations;")
#     execute(db, "INSERT INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
#     execute(db, "DETACH DATABASE merge_db;")
#     close(db)
#     return nothing
# end