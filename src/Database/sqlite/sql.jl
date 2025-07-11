using SQLite

const SQLiteDB = SQLite.DB
const SQL = String

function DB(db_info::SQLiteInfo; busy_timeout::Int=3000)
    db = SQLiteDB(db_info.filepath)
    SQLite.busy_timeout(db, busy_timeout)
    return db
end
db_begin_transaction(db::SQLiteDB) = SQLite.transaction(db) #does have a default mode that may be useful to change
db_execute(db::SQLiteDB, sql::SQL) = DBInterface.execute(db, sql)
db_execute(db::SQLiteDB, sql::SQL, params) = DBInterface.execute(db, sql, params)
db_query(db::SQLiteDB, sql::SQL) = DataFrame(db_execute(db, sql))
db_commit_transaction(db::SQLiteDB) = SQLite.commit(db)
db_close(db::SQLiteDB) = SQLite.close(db)


"""
    db_execute(filepath::String, sql::SQL)

Execute SQL on an sqlite database file specified by filepath.
"""
function db_execute(filepath::String, sql::SQL)
    db = DB(SQLiteInfo("temp", filepath))
    result = db_execute(db, sql)
    db_close(db)
    return result
end

"""
    db_execute(db_info::SQLiteInfo, sql::SQL)

Execute SQL on an sqlite database provided in an SQLiteInfo instance.
"""
function db_execute(db_info::SQLiteInfo, sql::SQL)    
    db = DB(db_info)
    query = db_execute(db, sql)
    db_close(db)
    return query
end


"""
    db_query(db_info::SQLiteInfo, sql::SQL)

Query the sqlite database provided in an SQLiteInfo instance with the sql (String) provided. Returns a DataFrame containing results.
"""
function db_query(db_info::SQLiteInfo, sql::SQL)                                                  
    db = DB(db_info)
    query = db_query(db, sql)
    db_close(db)
    return query
end

function db_query(query_dbs::Vector{SQLiteInfo}, sql::SQL)
    @assert !isempty(query_dbs) "query_dbs Vector is empty"                                                           
    db = DB(first(query_dbs))
    for query_db in query_dbs[2:end]
        db_execute(db, "ATTACH DATABASE '$(query_db.filepath)' as $(query_db.name);")
    end
    query = db_query(db, sql)
    for query_db in query_dbs[2:end]
        db_execute(db, "DETACH DATABASE $(query_db.name);")
    end
    db_close(db)
    return query
end

db_query(db_info::DatabaseSettings{SQLiteInfo}, sql::SQL) = db_query([main(db_info), attached(db_info)...], sql)


"""
    db_query(filepath::String, sql::SQL)

Quick method to query an sqlite database file specified by filepath. Returns a DataFrame containing results.
"""
db_query(filepath::String, sql::SQL) = db_query(SQLiteInfo("temp", filepath), sql)

"""
    db_query(db_info::SQLiteInfo, qp::QueryParams)

Query the sqlite database provided in an SQLiteInfo instance with the <:QueryParams instance provided. Returns a DataFrame containing results.
"""
db_query(db_info::Union{SQLiteInfo, Vector{SQLiteInfo}, DatabaseSettings{SQLiteInfo}}, qp::QueryParams) = db_query(db_info, sql(db_info, qp))


"""
    db_query(db_info::SQLiteInfo, qp::Query_simulations)

Query the sqlite database provided in an SQLiteInfo instance with the Query_simulations instance provided. Will throw an error if the database contains insufficient samples for any requested models. Returns a DataFrame containing results.
"""
function db_query(db_info::Union{SQLiteInfo, Vector{SQLiteInfo}, DatabaseSettings{SQLiteInfo}}, qp::Query_simulations; ensure_samples::Bool=true)      
    query = db_query(db_info, sql(db_info, qp))
    ensure_samples && _ensure_samples(query, qp)
    return query
end


function sql_create_games_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS games
    (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        game TEXT NOT NULL,
        payoff_matrix_size TEXT NOT NULL,
        UNIQUE(name, game)
    );
    """
end


function sql_create_graphmodels_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS graphmodels
    (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        display TEXT NOT NULL,
        params TEXT NOT NULL,
        kwargs TEXT NOT NULL,
        UNIQUE(name, params, kwargs)
    );
    """
end

function sql_create_graphmodel_parameters_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS graphmodel_parameters
    (
        id INTEGER PRIMARY KEY,
        graphmodel_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        FOREIGN KEY (graphmodel_id)
            REFERENCES graphmodels (id)
            ON DELETE CASCADE,
        UNIQUE(graphmodel_id, name)
        
    );
    """
end

function sql_create_parameters_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS parameters
    (
        id INTEGER PRIMARY KEY,
        number_agents INTEGER NOT NULL,
        memory_length INTEGER NOT NULL,
        error REAL NOT NULL,
        starting_condition TEXT NOT NULL,
        stopping_condition TEXT NOT NULL,
        parameters TEXT NOT NULL,
        UNIQUE(parameters)
    );
    """
end


function sql_create_models_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS models
    (
        id INTEGER PRIMARY KEY,
        game_id INTEGER NOT NULL,
        graphmodel_id INTEGER NOT NULL,
        parameters_id INTEGER NOT NULL,
        FOREIGN KEY (game_id)
            REFERENCES games (game_id)
            ON DELETE CASCADE,
        FOREIGN KEY (graphmodel_id)
            REFERENCES graphmodels (id)
            ON DELETE CASCADE,
        FOREIGN KEY (parameters_id)
            REFERENCES parameters (id)
            ON DELETE CASCADE,
        UNIQUE(game_id, graphmodel_id, parameters_id)
    );
    """
end

function sql_create_groups_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS groups
    (
        id INTEGER PRIMARY KEY,
        description TEXT DEFAULT NULL,
        UNIQUE(description)
    );
    """
end


function sql_create_simulations_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS simulations
    (
        uuid TEXT PRIMARY KEY,
        group_id INTEGER DEFAULT NULL,
        prev_simulation_uuid TEXT DEFAULT NULL,
        model_id INTEGER NOT NULL,
        period INTEGER NOT NULL,
        complete BOOLEAN NOT NULL,
        user_variables TEXT NOT NULL,
        data TEXT DEFAULT '{}' NOT NULL,
        state_bin BLOB DEFAULT NULL,
        FOREIGN KEY (group_id)
            REFERENCES groups (id)
            ON DELETE CASCADE,
        FOREIGN KEY (prev_simulation_uuid)
            REFERENCES simulations (simulation_uuid),
        FOREIGN KEY (model_id)
            REFERENCES models (id),
        UNIQUE(uuid),
        CHECK (complete in (0, 1))
    );
    """
end



function execute_init_db(db_info::SQLiteInfo)
    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_create_games_table(db_info))
    db_execute(db, sql_create_graphmodels_table(db_info))
    db_execute(db, sql_create_graphmodel_parameters_table(db_info))
    db_execute(db, sql_create_parameters_table(db_info))
    db_execute(db, sql_create_models_table(db_info))
    db_execute(db, sql_create_groups_table(db_info))
    db_execute(db, sql_create_simulations_table(db_info))
    db_commit_transaction(db)
    db_close(db)
end



function sql_insert_game(name::String, game_str::String, payoff_matrix_size::String)
    """
    INSERT OR IGNORE INTO games
    (
        name,
        game,
        payoff_matrix_size
    )
    VALUES
    (
        '$name',
        '$game_str',
        '$payoff_matrix_size'
    )
    ON CONFLICT (name, game) DO UPDATE
        SET name = games.name
    RETURNING id;
    """
end

function sql_insert_graphmodel(name::String, display::String, params::String, kwargs::String)
    """
    INSERT OR IGNORE INTO graphmodels
    (
        name,
        display,
        params,
        kwargs
    )
    VALUES
    (   
        '$name',
        '$display',
        '$params',
        '$kwargs'
    )
    ON CONFLICT (name, params, kwargs) DO UPDATE
        SET name = graphmodels.name
    RETURNING id;
    """
end

function sql_insert_graphmodel_parameter(graphmodel_id::Integer, name::String, type::String, value::String)
    """
    INSERT OR IGNORE INTO graphmodel_parameters
    (
        graphmodel_id,
        name,
        type,
        value
    )
    VALUES
    (   
        '$graphmodel_id',
        '$name',
        '$type',
        '$value'
    )
    ON CONFLICT (graphmodel_id, name) DO UPDATE
        SET name = graphmodel_parameters.name
    RETURNING id;
    """
end

function sql_insert_parameters(params::Types.Parameters, parameters_str::String) #NOTE: params should be broken up before this so we dont have to use Interactions functions*** (everything else is)
    """
    INSERT OR IGNORE INTO parameters
    (
        number_agents,
        memory_length,
        error,
        starting_condition,
        stopping_condition,
        parameters
    )
    VALUES
    (
        $(Types.number_agents(params)),
        $(Types.memory_length(params)),
        $(Types.error_rate(params)),
        '$(Types.starting_condition_fn_name(params))',
        '$(Types.stopping_condition_fn_name(params))',
        '$parameters_str'
    )
    ON CONFLICT (parameters) DO UPDATE
        SET number_agents = parameters.number_agents
    RETURNING id;
    """
end


function sql_insert_model(game_id::Integer, graphmodel_id::Integer, parameters_id::Integer; model_id::Union{Nothing, Integer}=nothing)
   """
    INSERT OR IGNORE INTO models
    (
        $(!isnothing(model_id) ? "id," : "")
        game_id,
        graphmodel_id,
        parameters_id
    )
    VALUES
    (
        $(!isnothing(model_id) ? "$model_id," : "")
        $game_id,
        $graphmodel_id,
        $parameters_id
    )
    ON CONFLICT (game_id, graphmodel_id, parameters_id) DO UPDATE
        SET game_id = models.game_id
    RETURNING id;
    """ 
end

function execute_insert_game(db::SQLiteDB, name::String, game_str::String, payoff_matrix_size::String)
    id::Int = db_query(db, sql_insert_game(name, game_str, payoff_matrix_size))[1, :id]
    return id
end

function execute_insert_graphmodel(db::SQLiteDB, name::String, display::String, kwargs::String, params::NamedTuple)
    id::Int = db_query(db, sql_insert_graphmodel(name, display, string(params), kwargs))[1, :id]
    for (param, val) in pairs(params)
        execute_insert_graphmodel_parameter(db, id, string(param), string(typeof(val)), string(val))
    end
    return id
end

function execute_insert_graphmodel_parameter(db::SQLiteDB, graphmodel_id::Integer, name::String, type::String, value::String)
    id::Int = db_query(db, sql_insert_graphmodel_parameter(graphmodel_id, name, type, value))[1, :id]
    return id
end

function execute_insert_parameters(db::SQLiteDB, params::Types.Parameters, parameters_str::String)
    id::Int = db_query(db, sql_insert_parameters(params, parameters_str))[1, :id]
    return id
end


function execute_insert_model(db_info::SQLiteInfo,
                            game_name::String, game_str::String, payoff_matrix_size::String,
                            graphmodel_name::String, graphmodel_display::String, graphmodel_kwargs::String, graphmodel_params::NamedTuple, #NOTE: should try to make all parameters String typed so they can be plugged right into sql
                            params::Types.Parameters, parameters_str::String;
                            model_id::Union{Nothing, Integer}=nothing)


    db = DB(db_info)
    db_begin_transaction(db)
    game_id = execute_insert_game(db, game_name, game_str, payoff_matrix_size)
    graphmodel_id = execute_insert_graphmodel(db, graphmodel_name, graphmodel_display, graphmodel_kwargs, graphmodel_params)
    parameters_id = execute_insert_parameters(db, params, parameters_str)
    # startingcondition_id = execute_insert_startingcondition(db, startingcondition_type, startingcondition_str)
    # stoppingcondition_id = execute_insert_stoppingcondition(db, stoppingcondition_type, stoppingcondition_str)
    # id = execute_insert_model(db, game_id, graphmodel_id, parameters_id, startingcondition_id, stoppingcondition_id)
    id::Int = db_query(db, sql_insert_model(game_id, graphmodel_id, parameters_id; model_id=model_id))[1, :id]
    db_commit_transaction(db)
    db_close(db)
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



function execute_insert_group(db_info::SQLiteInfo, description::String)
    db = DB(db_info)
    id::Int = db_query(db, sql_insert_group(description))[1, :id]
    db_close(db)
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


function execute_insert_simulation(db_info::SQLiteInfo,
                                    model_id::Integer,
                                    group_id::Union{Integer, Nothing},
                                    prev_simulation_uuid::Union{String, Nothing},
                                    period::Integer,
                                    complete::Integer,
                                    user_variables::String,
                                    data::String,
                                    state_bin::Union{Vector{UInt8}, Nothing}) #state_bin will be nothing if store_state=false in config
                                    
    uuid = "$(uuid4())"

    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_insert_simulation(), (uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data, state_bin))
    db_commit_transaction(db)
    db_close(db)
    return uuid
end



function sql_query_models(model_id::Integer)
    """
    SELECT
        models.id,
        parameters.parameters,
        graphmodels.graphmodel,
        games.game,
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
        games.game,
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


function execute_query_models(db_info::SQLiteInfo, model_id::Integer)
    db = DB(db_info)
    query = db_query(db, sql_query_models(model_id))
    db_close(db)
    return query
end

function execute_query_simulations_for_restore(db_info::SQLiteInfo, simulation_uuid::String)
    db = DB(db_info)
    simulation_query = db_query(db, sql_query_simulations(simulation_uuid))
    db_close(db)
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

function execute_query_incomplete_simulations(db_info::SQLiteInfo)
    db = DB(db_info)
    query = db_query(db, sql_query_incomplete_simulations())
    db_close(db)
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

db_query_timeseries(simulation_uuid::String, limit::Int) = db_query_timeseries(Interactions.DATABASE(), simulation_uuid, limit)
db_query_timeseries(db_info::SQLiteInfo, simulation_uuid::String, limit::Int) = db_query(db_info, sql_query_timeseries(simulation_uuid, limit))
db_query_timeseries(db_info::Vector{SQLiteInfo}, simulation_uuid::String, limit::Int) = db_query(db_info, sql_query_timeseries(simulation_uuid, limit))
db_query_timeseries(db_info::DatabaseSettings{SQLiteInfo}, simulation_uuid::String, limit::Int) = db_query(db_info, sql_query_timeseries(simulation_uuid, limit))


#NOTE: update this function!
function execute_merge_full(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo)
    db = DB(db_info_master)
    db = DB(db_info; busy_timeout=5000)
    db_execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")
    db_execute(db, "INSERT OR IGNORE INTO games(game_name, game, payoff_matrix_size) SELECT game_name, game, payoff_matrix_size FROM merge_db.games;")
    db_execute(db, "INSERT OR IGNORE INTO graphmodels(graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out) SELECT graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out FROM merge_db.graphmodels;")
    db_execute(db, "INSERT OR IGNORE INTO parameters(number_agents, memory_length, error, parameters) SELECT number_agents, memory_length, error, parameters FROM merge_db.parameters;")
    db_execute(db, "INSERT OR IGNORE INTO starting_conditions(name, starting_condition) SELECT name, starting_condition FROM merge_db.starting_conditions;")
    db_execute(db, "INSERT OR IGNORE INTO stopping_conditions(name, stopping_condition) SELECT name, stopping_condition FROM merge_db.stopping_conditions;")
    db_execute(db, "INSERT OR IGNORE INTO sim_groups(description) SELECT description FROM merge_db.sim_groups;")
    db_execute(db, "INSERT INTO simulations(simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, parameters_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, period) SELECT simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, parameters_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, period FROM merge_db.simulations;")
    db_execute(db, "INSERT INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    db_execute(db, "DETACH DATABASE merge_db;")
    db_close(db)
    return nothing
end

# Merge temp distributed DBs into master DB.
function execute_merge_temp(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo; collect_state::Bool=true)
    db = DB(db_info_master)
    # db = DB(db_info; busy_timeout=rand(1:5000)) #this caused issues on cluster (.nfsXXXX files were being created. Does this stop the database connection from being closed?) NOTE: are all of these executes separate writes? can we put them all into one???
    db_execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")

    if collect_state
        db_execute(db, "INSERT OR IGNORE INTO simulations(uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data, state_bin) SELECT uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data, state_bin FROM merge_db.simulations;")
    else
        db_execute(db, "INSERT OR IGNORE INTO simulations(uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data) SELECT uuid, group_id, prev_simulation_uuid, model_id, period, complete, user_variables, data FROM merge_db.simulations;")
    end

    db_execute(db, "DETACH DATABASE merge_db;")
    db_close(db)
    return nothing
end