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



function init(db_info::SQLiteInfo)
    mkpath(dirname(db_info.filepath)) #create the directory path if it doesn't already exist

    db = DB(db_info)
    begin_transaction(db)
    execute(db, load_sql_file(db_info, "games/init.sql"))
    execute(db, load_sql_file(db_info, "graphmodels/init.sql"))
    execute(db, load_sql_file(db_info, "graphmodels/graphmodel_parameters/init.sql"))
    execute(db, load_sql_file(db_info, "models/init.sql"))
    execute(db, load_sql_file(db_info, "models/model_parameters/init.sql"))
    execute(db, load_sql_file(db_info, "groups/init.sql"))
    execute(db, load_sql_file(db_info, "simulations/init.sql"))
    commit_transaction(db)
    close(db)
end


function insert_game(db_info::SQLiteInfo, game::Types.Game)
    id::Int = query(db_info, load_sql_file(db_info, "games/insert.sql"), (name(game), string(size(game)), Types.interaction_fn_name(game), serialize_to_vec(game)))[1, :id]
    return id
end


function insert_graphmodel(db_info::SQLiteInfo, graphmodel::Types.GraphModel)
    id::Int = query(db_info, load_sql_file(db_info, "graphmodels/insert.sql"), (Types.fn_name(graphmodel), Types.displayname(graphmodel), serialize_to_vec(graphmodel)))[1, :id]
    for (param, val) in pairs(Types.params(graphmodel))
        insert_graphmodel_parameter(db, id, string(param), string(typeof(val)), string(val))
    end
    return id
end


function insert_graphmodel_parameter(db::SQLitreInfo, graphmodel_id::Integer, name::String, type::String, value::String)
    id::Int = query(db, sql_insert_graphmodel_parameter(graphmodel_id, name, type, value))[1, :id]
    return id
end



function insert_model(db_info::SQLiteInfo,
                            game_name::String, game_str::String, payoff_matrix_size::String,
                            graphmodel_name::String, graphmodel_display::String, graphmodel_kwargs::String, graphmodel_params::NamedTuple, #NOTE: should try to make all parameters String typed so they can be plugged right into sql
                            params::Types.Parameters, parameters_str::String;
                            model_id::Union{Nothing, Integer}=nothing)


    db = DB(db_info)
    begin_transaction(db)
    game_id = insert_game(db, game_name, game_str, payoff_matrix_size)
    graphmodel_id = insert_graphmodel(db, graphmodel_name, graphmodel_display, graphmodel_kwargs, graphmodel_params)
    parameters_id = insert_parameters(db, params, parameters_str)
    # startingcondition_id = insert_startingcondition(db, startingcondition_type, startingcondition_str)
    # stoppingcondition_id = insert_stoppingcondition(db, stoppingcondition_type, stoppingcondition_str)
    # id = insert_model(db, game_id, graphmodel_id, parameters_id, startingcondition_id, stoppingcondition_id)
    id::Int = query(db, load_sql_file(db_info, "models/insert.sql"), (model_id, game_id, graphmodel_id, parameters_id))[1, :id]
    commit_transaction(db)
    close(db)
    return id
end


function insert_model_parameter(db::SQLitreInfo, params::Types.Parameters, parameters_str::String)
    id::Int = query(db, sql_insert_parameters(params, parameters_str))[1, :id]
    return id
end




function sql_insert_group(description::String)
    """
    INSERT OR IGNORE INTO groups
    (
        description
    )
    VALUES
    (
        '$description'
    )
    ON CONFLICT (description) DO UPDATE
        SET description = groups.description
    RETURNING id;
    """
end



function insert_group(db_info::SQLiteInfo, description::String)
    db = DB(db_info)
    id::Int = query(db, sql_insert_group(description))[1, :id]
    close(db)
    return id
end


function sql_insert_simulation()
    """
    INSERT INTO simulations
    (
        uuid,
        group_id,
        prev_simulation_uuid,
        model_id,
        period,
        complete,
        user_variables,
        data,
        state_bin
    )
    VALUES (?,?,?,?,?,?,?,?,?)
    """
end


function insert_simulation(db_info::SQLiteInfo,
                                    model_id::Integer,
                                    group_id::Union{Integer, Nothing},
                                    prev_simulation_uuid::Union{String, Nothing},
                                    period::Integer,
                                    complete::Integer,
                                    user_variables::String,
                                    data::String,
                                    state_bin::Union{BLOB, Nothing}) #state_bin will be nothing if store_state=false in config
                                    
    uuid = "$(uuid4())"

    db = DB(db_info)
    begin_transaction(db)
    execute(db, sql_insert_simulation(), (uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data, state_bin))
    commit_transaction(db)
    close(db)
    return uuid
end



function sql_query_models(model_id::Integer)
    """
    SELECT
        models.id,
        parameters.parameters,
        graphmodels.graphmodel,
        games.game_bin,
        games.payoff_matrix_size
    FROM models
    INNER JOIN games ON models.game_id = games.id
    INNER JOIN graphmodels ON models.graphmodel_id = graphmodels.id
    INNER JOIN parameters ON models.parameters_id = parameters.id
    WHERE models.id = $model_id;
    """
end

function sql_query_simulations(simulation_uuid::String)
    """
    SELECT
        simulations.uuid,
        simulations.prev_simulation_uuid,
        simulations.model_id,
        simulations.state_bin,
        parameters.parameters,
        games.game_bin,
        games.payoff_matrix_size,
        graphmodels.graphmodel,
        simulations.group_id,
        simulations.period,
        simulations.complete,
        simulations.user_variables
    FROM simulations
    INNER JOIN models ON simulations.model_id = models.id
    INNER JOIN games ON models.game_id = games.id
    INNER JOIN graphmodels ON models.graphmodel_id = graphmodels.id
    INNER JOIN parameters ON models.parameters_id = parameters.id
    WHERE simulations.uuid = '$simulation_uuid';
    """
end


function query_models(db_info::SQLiteInfo, model_id::Integer)
    db = DB(db_info)
    query = query(db, sql_query_models(model_id))
    close(db)
    return query
end

function query_simulations_for_restore(db_info::SQLiteInfo, simulation_uuid::String)
    db = DB(db_info)
    simulation_query = query(db, sql_query_simulations(simulation_uuid))
    close(db)
    return simulation_query
end

function sql_query_incomplete_simulations()
    """
    SELECT uuid
    FROM simulations tabA
    WHERE complete = 0
    AND NOT EXISTS (
        SELECT *
        FROM simulations tabB
        WHERE tabB.prev_simulation_uuid = tabA.uuid
    )
    """
end

function query_incomplete_simulations(db_info::SQLiteInfo)
    db = DB(db_info)
    query = query(db, sql_query_incomplete_simulations())
    close(db)
    return query
end


function sql_query_timeseries(simulation_uuid::String, limit::Int)
    """
    WITH RECURSIVE
        timeseries(i, uuid, prev_simulation_uuid, period, complete, data) AS (
            SELECT $limit, simulations.uuid, simulations.prev_simulation_uuid, simulations.period, simulations.complete, simulations.data
            FROM simulations
            WHERE simulations.uuid = '$simulation_uuid'
            UNION ALL
            SELECT i - 1, simulations.uuid, simulations.prev_simulation_uuid, simulations.period, simulations.complete, simulations.data
            FROM simulations, timeseries
            WHERE simulations.uuid = timeseries.prev_simulation_uuid
            AND i - 1 > 0
        )
    SELECT *
    FROM timeseries
    ORDER BY i ASC
    """
end

query_timeseries(db_info::SQLiteInfo, simulation_uuid::String, limit::Int) = query(db_info, sql_query_timeseries(simulation_uuid, limit))
query_timeseries(db_info::Vector{SQLiteInfo}, simulation_uuid::String, limit::Int) = query(db_info, sql_query_timeseries(simulation_uuid, limit))
query_timeseries(db_info::DatabaseSettings{SQLiteInfo}, simulation_uuid::String, limit::Int) = query(db_info, sql_query_timeseries(simulation_uuid, limit))


#NOTE: update this function!
function merge_full(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo)
    db = DB(db_info_master)
    db = DB(db_info; busy_timeout=5000)
    execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")
    execute(db, "INSERT OR IGNORE INTO games(game_name, game_bin, payoff_matrix_size) SELECT game_name, game_bin, payoff_matrix_size FROM merge_db.games;")
    execute(db, "INSERT OR IGNORE INTO graphmodels(graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out) SELECT graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out FROM merge_db.graphmodels;")
    execute(db, "INSERT OR IGNORE INTO parameters(number_agents, memory_length, error, parameters) SELECT number_agents, memory_length, error, parameters FROM merge_db.parameters;")
    execute(db, "INSERT OR IGNORE INTO starting_conditions(name, starting_condition) SELECT name, starting_condition FROM merge_db.starting_conditions;")
    execute(db, "INSERT OR IGNORE INTO stopping_conditions(name, stopping_condition) SELECT name, stopping_condition FROM merge_db.stopping_conditions;")
    execute(db, "INSERT OR IGNORE INTO sim_groups(description) SELECT description FROM merge_db.sim_groups;")
    execute(db, "INSERT INTO simulations(simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, parameters_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, period) SELECT simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, parameters_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, period FROM merge_db.simulations;")
    execute(db, "INSERT INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    execute(db, "DETACH DATABASE merge_db;")
    close(db)
    return nothing
end

# Merge temp distributed DBs into master DB.
function merge_temp(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo; collect_state::Bool=true)
    db = DB(db_info_master)
    # db = DB(db_info; busy_timeout=rand(1:5000)) #this caused issues on cluster (.nfsXXXX files were being created. Does this stop the database connection from being closed?) NOTE: are all of these executes separate writes? can we put them all into one???
    execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")

    if collect_state
        execute(db, "INSERT OR IGNORE INTO simulations(uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data, state_bin) SELECT uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data, state_bin FROM merge_db.simulations;")
    else
        execute(db, "INSERT OR IGNORE INTO simulations(uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data) SELECT uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data FROM merge_db.simulations;")
    end

    execute(db, "DETACH DATABASE merge_db;")
    close(db)
    return nothing
end