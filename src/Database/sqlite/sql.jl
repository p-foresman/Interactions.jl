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

#NOTE: graphmodels are a sub-model, so treat it the same way models are treated? (individual graph type parameters shouldnt be stored in this table)
# function sql_create_graphmodels_table(::SQLiteInfo)
#     """
#     CREATE TABLE IF NOT EXISTS graphmodels
#     (
#         id INTEGER PRIMARY KEY,
#         display TEXT NOT NULL,
#         type TEXT NOT NULL,
#         graphmodel TEXT NOT NULL,
#         λ REAL DEFAULT NULL,
#         β REAL DEFAULT NULL,
#         α REAL DEFAULT NULL,
#         blocks INTEGER DEFAULT NULL,
#         p_in REAL DEFAULT NULL,
#         p_out REAL DEFAULT NULL,
#         UNIQUE(graphmodel)
#     );
#     """
# end

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

# function sql_create_startingconditions_table(::SQLiteInfo)
#     """
#     CREATE TABLE IF NOT EXISTS startingconditions
#     (
#         id INTEGER PRIMARY KEY,
#         type TEXT NOT NULL,
#         startingcondition TEXT NOT NULL,
#         UNIQUE(type, startingcondition)
#     );
#     """
# end

# function sql_create_stoppingconditions_table(::SQLiteInfo)
#     """
#     CREATE TABLE IF NOT EXISTS stoppingconditions
#     (
#         id INTEGER PRIMARY KEY,
#         type TEXT NOT NULL,
#         stoppingcondition TEXT NOT NULL,
#         UNIQUE(type, stoppingcondition)
#     );
#     """
# end

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

# function sql_create_graphs_table(::SQLiteInfo)
#     """
#     CREATE TABLE IF NOT EXISTS graphs
#     (
#         id INTEGER PRIMARY KEY,
#         model_id INTEGER NOT NULL,
#         graph_adj_matrix TEXT NOT NULL,
#         FOREIGN KEY (model_id)
#             REFERENCES models (id),
#         UNIQUE(model_id, graph_adj_matrix)
#     );
#     """
# end

function sql_create_simulations_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS simulations
    (
        uuid TEXT PRIMARY KEY,
        group_id INTEGER DEFAULT NULL,
        prev_simulation_uuid TEXT DEFAULT NULL,
        model_id INTEGER NOT NULL,
        rng_state TEXT NOT NULL,
        random_seed INTEGER DEFAULT NULL,
        graph_adj_matrix TEXT DEFAULT NULL,
        period INTEGER NOT NULL,
        complete BOOLEAN NOT NULL,
        user_variables TEXT NOT NULL,
        data TEXT DEFAULT '{}' NOT NULL,
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

# function sql_create_simulations_table(::SQLiteInfo)
#     """
#     CREATE TABLE IF NOT EXISTS simulations
#     (
#         uuid TEXT PRIMARY KEY,
#         group_id INTEGER DEFAULT NULL,
#         prev_simulation_uuid TEXT DEFAULT NULL,
#         model_id INTEGER NOT NULL,
#         graph_adj_matrix TEXT NOT NULL,
#         rng_state TEXT NOT NULL,
#         period INTEGER NOT NULL,
#         FOREIGN KEY (group_id)
#             REFERENCES groups (id)
#             ON DELETE CASCADE,
#         FOREIGN KEY (prev_simulation_uuid)
#             REFERENCES simulations (simulation_uuid),
#         FOREIGN KEY (model_id)
#             REFERENCES models (id),
#         UNIQUE(uuid)
#     );
#     """
# end


function sql_create_agents_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS agents
    (
        id INTEGER PRIMARY KEY,
        simulation_uuid TEXT NOT NULL,
        agent TEXT NOT NULL,
        FOREIGN KEY (simulation_uuid)
            REFERENCES simulations (simulation_uuid)
            ON DELETE CASCADE
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
    # db_execute(db, sql_create_startingconditions_table(db_info))
    # db_execute(db, sql_create_stoppingconditions_table(db_info))
    db_execute(db, sql_create_models_table(db_info))
    db_execute(db, sql_create_groups_table(db_info))
    db_execute(db, sql_create_simulations_table(db_info))
    db_execute(db, sql_create_agents_table(db_info))
    db_commit_transaction(db)
    db_close(db)
end

#this DB only needs tables for simulations and agents. These will be collected into the master DB later
function execute_init_db_temp(db_info::SQLiteInfo)
    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_create_simulations_table(db_info))
    db_execute(db, sql_create_agents_table(db_info))
    db_commit_transaction(db)
    db_close(db)
end

#NOTE: remove later
#quick and dirty way to add graph type
function add_graph_type(db_filepath)
    graph_types = ["complete", "er", "sf", "sw", "sbm"]
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    DBInterface.execute(db, "ALTER TABLE graphs
                        RENAME COLUMN graph_type TO graph";)
    DBInterface.execute(db, "ALTER TABLE graphs
                        ADD graph_type TEXT NOT NULL DEFAULT ``";)
    query = DBInterface.execute(db, "SELECT COUNT(*) FROM graphs";)
    df = DataFrame(query)
    for row in 1:df[1, "COUNT(*)"]
        query = DBInterface.execute(db, "SELECT graph_params FROM graphs WHERE graph_id == $row";)
        params = DataFrame(query)[1, "graph_params"]
        for graph_type in graph_types
            if occursin(graph_type, params)
                DBInterface.execute(db, "UPDATE graphs SET graph_type = '$graph_type' WHERE graph_id = $row";)
            end
        end
    end
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

function sql_insert_parameters(params::Parameters, parameters_str::String) #NOTE: params should be broken up before this so we dont have to use Interactions functions
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
        $(Interactions.number_agents(params)),
        $(Interactions.memory_length(params)),
        $(Interactions.error_rate(params)),
        '$(Interactions.starting_condition_fn_name(params))',
        '$(Interactions.stopping_condition_fn_name(params))',
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

function execute_insert_parameters(db::SQLiteDB, params::Parameters, parameters_str::String)
    id::Int = db_query(db, sql_insert_parameters(params, parameters_str))[1, :id]
    return id
end

# function execute_insert_startingcondition(db::SQLiteDB, type::String, startingcondition_str::String)
#     id::Int = db_query(db, sql_insert_startingcondition(type, startingcondition_str))[1, :id]
#     return id
# end

# function execute_insert_stoppingcondition(db::SQLiteDB, type::String, stoppingcondition_str::String)
#     id::Int = db_query(db, sql_insert_stoppingcondition(type, stoppingcondition_str))[1, :id]
#     return id
# end

#dont want to be able to insert a model without all the other components (although could be useful to create new models in the database to choose from?)
# function execute_insert_model(db::SQLiteDB, game_id::Integer, graphmodel_id::Integer, parameters_id::Integer, startingcondition_id::Integer, stoppingcondition_id::Integer)
#     id::Int = db_query(db, sql_insert_model(game_id, graphmodel_id, parameters_id, startingcondition_id, stoppingcondition_id))[1, :id]
#     return id
# end

function execute_insert_model(db_info::SQLiteInfo,
                            game_name::String, game_str::String, payoff_matrix_size::String,
                            graphmodel_name::String, graphmodel_display::String, graphmodel_kwargs::String, graphmodel_params::NamedTuple, #NOTE: should try to make all parameters String typed so they can be plugged right into sql
                            params::Parameters, parameters_str::String;
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


####################################################



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


function sql_insert_simulation(uuid::String, group_id::String, prev_simulation_uuid::String, model_id::Integer, rng_state::String, random_seed::String, graph_adj_matrix_str::String, period::Integer, complete::Integer, user_variables::String, data::String)
    """
    INSERT INTO simulations
    (
        uuid,
        group_id,
        prev_simulation_uuid,
        model_id,
        rng_state,
        random_seed,
        graph_adj_matrix,
        period,
        complete,
        user_variables,
        data
    )
    VALUES
    (
        '$uuid',
        $group_id,
        $(prev_simulation_uuid == "NULL" ? prev_simulation_uuid : "'$prev_simulation_uuid'"),
        $model_id,
        '$rng_state',
        $random_seed,
        '$graph_adj_matrix_str',
        $period,
        $complete,
        '$user_variables',
        '$data'

    );
    ON CONFLICT () DO UPDATE
        SET group_id = simulations.group_id
    RETURNING uuid
    """
end

function sql_insert_agents(agent_values_string::String) #kind of a cop-out parameter but fine for now
    """
    INSERT INTO agents
    (
        simulation_uuid,
        agent
    )
    VALUES
        $agent_values_string;
    """
end

function execute_insert_simulation(db_info::SQLiteInfo,
                                    model_id::Integer,
                                    group_id::Union{Integer, Nothing},
                                    prev_simulation_uuid::Union{String, Nothing},
                                    rng_state::String,
                                    random_seed::Union{Integer, Nothing},
                                    graph_adj_matrix_str::String,
                                    period::Integer,
                                    complete::Integer,
                                    user_variables::String,
                                    data::String,
                                    agent_list::Vector{String})
                                    
    uuid = "$(uuid4())"
    
    #prepare simulation SQL
    group_id = isnothing(group_id) ? "NULL" : string(group_id)
    isnothing(prev_simulation_uuid) ?  prev_simulation_uuid = "NULL" : nothing
    random_seed = isnothing(random_seed) ? "NULL" : string(random_seed)

    #prepare agents SQL
    agent_values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        agent_values_string *= "('$uuid', '$agent'), "
    end
    agent_values_string = string(rstrip(agent_values_string, [' ', ',']))

    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_insert_simulation(uuid, group_id, prev_simulation_uuid, model_id, rng_state, random_seed, graph_adj_matrix_str, period, complete, user_variables, data))
    db_execute(db, sql_insert_agents(agent_values_string))
    db_commit_transaction(db)
    db_close(db)
    return uuid
end


#for partial insert
function sql_insert_simulation(uuid::String, group_id::String, prev_simulation_uuid::String, model_id::Integer, rng_state::String, random_seed::String, period::Integer, complete::Integer, user_variables::String, data::String)
    """
    INSERT INTO simulations
    (
        uuid,
        group_id,
        prev_simulation_uuid,
        model_id,
        rng_state,
        random_seed,
        period,
        complete,
        user_variables,
        data
    )
    VALUES
    (
        '$uuid',
        $group_id,
        $(prev_simulation_uuid == "NULL" ? prev_simulation_uuid : "'$prev_simulation_uuid'"),
        $model_id,
        '$rng_state',
        $random_seed,
        $period,
        $complete,
        '$user_variables',
        '$data'

    );
    ON CONFLICT () DO UPDATE
        SET group_id = simulations.group_id
    RETURNING uuid
    """
end

function execute_insert_simulation(db_info::SQLiteInfo,
                                    model_id::Integer,
                                    group_id::Union{Integer, Nothing},
                                    prev_simulation_uuid::Union{String, Nothing},
                                    rng_state::String,
                                    random_seed::Union{Integer, Nothing},
                                    period::Integer,
                                    complete::Integer,
                                    user_variables::String,
                                    data::String)
                                    
    uuid = "$(uuid4())"
    
    #prepare simulation SQL
    group_id = isnothing(group_id) ? "NULL" : string(group_id)
    isnothing(prev_simulation_uuid) ?  prev_simulation_uuid = "NULL" : nothing
    random_seed = isnothing(random_seed) ? "NULL" : string(random_seed)

    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_insert_simulation(uuid, group_id, prev_simulation_uuid, model_id, rng_state, random_seed, period, complete, user_variables, data))
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
        simulations.random_seed,
        simulations.graph_adj_matrix,
        parameters.parameters,
        games.game,
        games.payoff_matrix_size,
        graphmodels.graphmodel,
        simulations.group_id,
        simulations.rng_state,
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

function sql_query_agents(simulation_uuid::String)
    """
    SELECT agent
    FROM agents
    WHERE simulation_uuid = '$simulation_uuid'
    ORDER BY id ASC;
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
    db_begin_transaction(db)
    simulation_query = db_query(db, sql_query_simulations(simulation_uuid))
    agents_query = db_query(db, sql_query_agents(simulation_uuid))
    db_commit_transaction(db)
    db_close(db)
    return (simulation_query, agents_query)
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



db_query_agents(simulation_uuid::String) = db_query_agents(Interactions.DATABASE(), simulation_uuid)
db_query_agents(db_info::SQLiteInfo, simulation_uuid::String) = db_query(db_info, sql_query_agents(simulation_uuid))
db_query_agents(db_info::Vector{SQLiteInfo}, simulation_uuid::String) = db_query(db_info, sql_query_agents(simulation_uuid))
db_query_agents(db_info::DatabaseSettings{SQLiteInfo}, simulation_uuid::String) = db_query(db_info, sql_query_agents(simulation_uuid))



# function execute_query_agents_for_restore(db_info::SQLiteInfo, simulation_uuid::String)
#     db = DB(db_info; busy_timeout=3000)
#     query = DBInterface.execute(db, "
#                                         SELECT agent
#                                         FROM agents
#                                         WHERE simulation_id = $simulation_id
#                                         ORDER BY agent_id ASC;
#                                 ")
#     df = DataFrame(query) #must create a DataFrame to acces query data
#     db_close(db)
#     return df
# end


#NOTE: FIX
# function querySimulationsByGroup(db_info::SQLiteInfo, group_id::Int)
#   
#     db = DB(db_info; busy_timeout=3000)
#     query = DBInterface.execute(db, "
#                                         SELECT
#                                             simulations.simulation_id,
#                                             simulations.group_id,
#                                             simulations.parameters_id,
#                                             simulations.graph_adj_matrix,
#                                             simulations.random_seed,
#                                             simulations.rng_state,
#                                             simulations.period,
#                                             games.game,
#                                             games.payoff_matrix_size,
#                                             graphmodels.graph_params
#                                         FROM simulations
#                                         INNER JOIN games USING(game_id)
#                                         INNER JOIN graphmodels USING(graph_id)
#                                         INNER JOIN parameters USING(parameters_id)
#                                         WHERE simulations.group_id = $group_id
#                                 ")
#     df = DataFrame(query) #must create a DataFrame to acces query data
#     db_close(db)
#     return df
# end

#this function allows for RAM space savings during large iterative simulations
function querySimulationIDsByGroup(db_info::SQLiteInfo, group_id::Int)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulation_id
                                        FROM simulations
                                        WHERE group_id = $group_id
                                        ORDER BY simulation_id ASC
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_delete_simulation(db_info::SQLiteInfo, simulation_id::Int)
    db = DB(db_info; busy_timeout=3000)
    db_execute(db, "PRAGMA foreign_keys = ON;") #turn on foreign key support to allow cascading deletes
    status = db_execute(db, "DELETE FROM simulations WHERE simulation_id = $simulation_id;")
    db_close(db)
    return status
end


# Merge two SQLite files. These db files MUST have the same schema
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
function execute_merge_temp(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo; collect_adj_matrix::Bool=true, collect_agents::Bool=true)
    db = DB(db_info_master)
    # db = DB(db_info; busy_timeout=rand(1:5000)) #this caused issues on cluster (.nfsXXXX files were being created. Does this stop the database connection from being closed?) NOTE: are all of these executes separate writes? can we put them all into one???
    db_execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")

    if collect_adj_matrix
        db_execute(db, "INSERT OR IGNORE INTO simulations(uuid, group_id, prev_simulation_uuid, model_id, rng_state, random_seed, graph_adj_matrix, period, complete, user_variables, data) SELECT uuid, group_id, prev_simulation_uuid, model_id, rng_state, random_seed, graph_adj_matrix, period, complete, user_variables, data FROM merge_db.simulations;")
    else
        db_execute(db, "INSERT OR IGNORE INTO simulations(uuid, group_id, prev_simulation_uuid, model_id, rng_state, random_seed, period, complete, user_variables, data) SELECT uuid, group_id, prev_simulation_uuid, model_id, rng_state, random_seed, period, complete, user_variables, data FROM merge_db.simulations;")
    end

    if collect_agents
        db_execute(db, "INSERT OR IGNORE INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    end

    db_execute(db, "DETACH DATABASE merge_db;")
    db_close(db)
    return nothing
end



function querySimulationsForBoxPlot(db_info::SQLiteInfo; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Int)
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY graph_id
                                                    ORDER BY graph_id, simulation_id
                                                ) RowNum,
                                                simulations.simulation_id,
                                                parameters.parameters,
                                                parameters.number_agents,
                                                parameters.memory_length,
                                                parameters.error,
                                                simulations.period,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN parameters USING(parameters_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND parameters.number_agents = $number_agents
                                            AND parameters.memory_length = $memory_length
                                            AND parameters.error = $error
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ") #dont need ROW_NUMBER() above, keeping for future use reference
    df = DataFrame(query)
    db_close(db)

    #error handling
    error_set = Set([])
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in df[:, :graph_id]]) : nothing

    for graph_id in graph_ids
        filtered_df = filter(:graph_id => id -> id == graph_id, df)
        if nrow(filtered_df) < sample_size
            push!(error_set, filtered_df[1, :graph])
        end
    end
    if !isempty(error_set)
        throw(ErrorException("Not enough samples for the following graphmodels: $error_set"))
    else
        return df
    end
end


function querySimulationsForMemoryLengthLinePlot(db_info::SQLiteInfo; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
    memory_lengths_sql = ""
    if memory_length_list !== nothing
        length(memory_length_list) == 1 ? memory_lengths_sql *= "AND parameters.memory_length = $(memory_length_list[1])" : memory_lengths_sql *= "AND parameters.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND parameters.error = $(errors[1])" : errors_sql *= "AND parameters.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end


    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY parameters.memory_length, parameters.error, simulations.graph_id
                                                    ORDER BY parameters.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                parameters.parameters,
                                                parameters.number_agents,
                                                parameters.memory_length,
                                                parameters.error,
                                                simulations.period,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN parameters USING(parameters_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND parameters.number_agents = $number_agents
                                            $memory_lengths_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)


    #error handling
    function memoryLengthsDF() DataFrame(DBInterface.execute(db, "SELECT memory_length FROM parameters")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM parameters")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    memory_length_list === nothing ? memory_length_list = Set([memory_length for memory_length in memoryLengthsDF()[:, :memory_length]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for memory_length in memory_length_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:memory_length, :error, :graph_id] => (len, err, id) -> len == memory_length && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end




function querySimulationsForNumberAgentsLinePlot(db_info::SQLiteInfo; game_id::Integer, number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing, memory_length::Integer, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
    number_agents_sql = ""
    if number_agents_list !== nothing
        length(number_agents_list) == 1 ? number_agents_sql *= "AND parameters.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND parameters.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND parameters.error = $(errors[1])" : errors_sql *= "AND parameters.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end


    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY parameters.number_agents, parameters.error, simulations.graph_id
                                                    ORDER BY parameters.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                parameters.parameters,
                                                parameters.number_agents,
                                                parameters.memory_length,
                                                parameters.error,
                                                simulations.period,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN parameters USING(parameters_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND parameters.memory_length = $memory_length
                                            $number_agents_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)


    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM parameters")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM parameters")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end


function query_simulations_for_transition_time_vs_memory_sweep(db_info::SQLiteInfo;
                                                                game_id::Integer,
                                                                memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                number_agents::Integer,
                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                starting_condition_id::Integer,
                                                                stopping_condition_id::Integer,
                                                                sample_size::Integer
    )    
                                                                                
    memory_length_sql = ""
    if memory_length_list !== nothing
        length(memory_length_list) == 1 ? memory_length_sql *= "AND parameters.memory_length = $(memory_length_list[1])" : memory_length_sql *= "AND parameters.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND parameters.error = $(errors[1])" : errors_sql *= "AND parameters.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end

    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY parameters.memory_length, parameters.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY parameters.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                parameters.parameters,
                                                parameters.number_agents,
                                                parameters.memory_length,
                                                parameters.error,
                                                simulations.period,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN parameters USING(parameters_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND parameters.number_agents = $number_agents
                                            $memory_length_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM parameters")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM parameters")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end




# function sql_query_simulations_for_transition_time_vs_population_sweep(game_id::Integer,
#                                                                         starting_condition::String, 
#                                                                         stopping_condition::String,
#                                                                         memory_length::Integer,
#                                                                         number_agents_sql::String,
#                                                                         error_rates_sql::String,
#                                                                         graph_ids_sql::String,
#                                                                         sample_size::Integer
#     )
#     #parameters.number_agents, parameters.error, parameters.starting_condition, parameters.stopping_condition, models.graphmodel_id
#     """
#     SELECT * FROM (
#         SELECT
#             ROW_NUMBER() OVER ( 
#                 PARTITION BY models.id
#                 ORDER BY RANDOM()
#             ) RowNum,
#             models.id as model_id,
#             simulations.uuid,
#             parameters.parameters,
#             parameters.number_agents,
#             parameters.memory_length,
#             parameters.error,
#             parameters.starting_condition,
#             parameters.stopping_condition,
#             simulations.period,
#             models.graphmodel_id,
#             graphmodels.type,
#             graphmodels.graphmodel,
#             graphmodels.λ,
#             games.name
#         FROM models
#         INNER JOIN simulations ON models.id = simulations.model_id
#         INNER JOIN parameters ON models.parameters_id = parameters.id
#         INNER JOIN games ON models.game_id = games.id
#         INNER JOIN graphmodels ON models.graphmodel_id = graphmodels.id
#         WHERE simulations.complete = 1 
#         AND models.game_id = $game_id
#         AND parameters.starting_condition = '$starting_condition'
#         AND parameters.stopping_condition = '$stopping_condition'
#         AND parameters.memory_length = $memory_length
#         $number_agents_sql
#         $error_rates_sql
#         $graph_ids_sql
#         )
#     WHERE RowNum <= $sample_size;
#     """
# end



# function query_simulations_for_transition_time_vs_population_sweep(db_info::SQLiteInfo;
#                                                                     game_id::Integer,
#                                                                     number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
#                                                                     memory_length::Integer,
#                                                                     error_rates::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
#                                                                     graphmodel_ids::Union{Vector{<:Integer}, Nothing} = nothing,
#                                                                     starting_condition::String,
#                                                                     stopping_condition::String,
#                                                                     sample_size::Integer)    
                                                                                
#     number_agents_sql = ""
#     if number_agents_list !== nothing
#         length(number_agents_list) == 1 ? number_agents_sql *= "AND parameters.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND parameters.number_agents IN $(Tuple(number_agents_list))"
#     end
#     error_rates_sql = ""
#     if error_rates !== nothing
#         length(error_rates) == 1 ? error_rates_sql *= "AND parameters.error = $(error_rates[1])" : error_rates_sql *= "AND parameters.error IN $(Tuple(error_rates))"
#     end
#     graphmodel_ids_sql = ""
#     if graphmodel_ids !== nothing
#         length(graphmodel_ids) == 1 ? graphmodel_ids_sql *= "AND models.graphmodel_id = $(graphmodel_ids[1])" : graphmodel_ids_sql *= "AND models.graphmodel_id IN $(Tuple(graphmodel_ids))"
#     end

#     db = DB(db_info)
#     query = db_query(db, sql_query_simulations_for_transition_time_vs_population_sweep(game_id,
#                                                                                                 starting_condition, 
#                                                                                                 stopping_condition,
#                                                                                                 memory_length,
#                                                                                                 number_agents_sql,
#                                                                                                 error_rates_sql,
#                                                                                                 graphmodel_ids_sql,
#                                                                                                 sample_size)
#     )
#     close(db)

#     #check to ensure all samples are present
#     model_counts_df = combine(groupby(query, :model_id), nrow=>:count)
#     insufficient_samples_str = ""
#     for row in eachrow(model_counts_df)
#         if row[:count] < sample_size
#             insufficient_samples_str *= "only $(row[:count]) samples for model $(row[:model_id])\n"
#         end
#     end
#     !isempty(insufficient_samples_str) && throw(ErrorException("Insufficient samples for the following:\n" * insufficient_samples_str))
    
#     #if a model has 0 samples, it won't show up in dataframe (it wasn't simulated)
#     if nrow(model_counts_df) < Interactions.volume(number_agents_list, error_rates, graphmodel_ids)
#         throw(ErrorException("At least one model selected has no simulations"))
#     end

#     return query
# end


# function query_population_sweep(db_info::SQLiteInfo, qp::Query_simulations)                                                                 
#     db = DB(db_info)
#     query = db_query(db, sql(qp))
#     close(db)

#     _ensure_samples(query, qp)

#     return query
# end


function query_simulations_for_transition_time_vs_population_stopping_condition(db_info::SQLiteInfo;
                                                                                game_id::Integer,
                                                                                number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                memory_length::Integer,
                                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                                graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                starting_condition_ids::Vector{<:Integer},
                                                                                stopping_condition_ids::Vector{<:Integer},
                                                                                sample_size::Integer)    
                                                                                
    number_agents_sql = ""
    if number_agents_list !== nothing
        length(number_agents_list) == 1 ? number_agents_sql *= "AND parameters.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND parameters.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND parameters.error = $(errors[1])" : errors_sql *= "AND parameters.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    starting_condition_ids_sql = ""
    length(starting_condition_ids) == 1 ? starting_condition_ids_sql *= "AND simulations.starting_condition_id = $(starting_condition_ids[1])" : starting_condition_ids_sql *= "AND simulations.starting_condition_id IN $(Tuple(starting_condition_ids))"
    stopping_condition_ids_sql = ""
    length(stopping_condition_ids) == 1 ? stopping_condition_ids_sql *= "AND simulations.stopping_condition_id = $(stopping_condition_ids[1])" : stopping_condition_ids_sql *= "AND simulations.stopping_condition_id IN $(Tuple(stopping_condition_ids))"

    println(graph_ids_sql)
    println(starting_condition_ids_sql)

    println(stopping_condition_ids_sql)

    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY parameters.number_agents, parameters.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY parameters.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                parameters.parameters,
                                                parameters.number_agents,
                                                parameters.memory_length,
                                                parameters.error,
                                                simulations.period,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN parameters USING(parameters_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND parameters.memory_length = $memory_length
                                            $number_agents_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            $starting_condition_ids_sql
                                            $stopping_condition_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM parameters")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM parameters")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end



function query_simulations_for_transition_time_vs_memory_length_stopping_condition(db_info::SQLiteInfo;
                                                                                game_id::Integer,
                                                                                memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                number_agents::Integer,
                                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                                graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                starting_condition_ids::Vector{<:Integer},
                                                                                stopping_condition_ids::Vector{<:Integer},
                                                                                sample_size::Integer)    
                                                                                
    memory_lengths_sql = ""
    if memory_length_list !== nothing
        length(memory_length_list) == 1 ? memory_lengths_sql *= "AND parameters.memory_length = $(memory_length_list[1])" : memory_lengths_sql *= "AND parameters.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND parameters.error = $(errors[1])" : errors_sql *= "AND parameters.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    starting_condition_ids_sql = ""
    length(starting_condition_ids) == 1 ? starting_condition_ids_sql *= "AND simulations.starting_condition_id = $(starting_condition_ids[1])" : starting_condition_ids_sql *= "AND simulations.starting_condition_id IN $(Tuple(starting_condition_ids))"
    stopping_condition_ids_sql = ""
    length(stopping_condition_ids) == 1 ? stopping_condition_ids_sql *= "AND simulations.stopping_condition_id = $(stopping_condition_ids[1])" : stopping_condition_ids_sql *= "AND simulations.stopping_condition_id IN $(Tuple(stopping_condition_ids))"

    println(graph_ids_sql)
    println(starting_condition_ids_sql)

    println(stopping_condition_ids_sql)

    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY parameters.memory_length, parameters.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY parameters.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                parameters.parameters,
                                                parameters.number_agents,
                                                parameters.memory_length,
                                                parameters.error,
                                                simulations.period,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN parameters USING(parameters_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND parameters.number_agents = $number_agents
                                            $memory_lengths_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            $starting_condition_ids_sql
                                            $stopping_condition_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM parameters")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM parameters")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end



function querySimulationsForTimeSeries(db_info::SQLiteInfo;group_id::Integer)
    db = DB(db_info; busy_timeout=3000)

    #query the simulation info (only need one row since each entry in the timeseries group will have the same info)
    #separate this from agent query to save memory, as this query could be very memory intensive
    query_sim_info = DBInterface.execute(db, "
                                                SELECT
                                                    simulations.simulation_id,
                                                    parameters.parameters,
                                                    parameters.number_agents,
                                                    parameters.memory_length,
                                                    parameters.error,
                                                    graphmodels.graph_id,
                                                    graphmodels.graph,
                                                    graphmodels.graph_params,
                                                    games.game_name,
                                                    games.game,
                                                    games.payoff_matrix_size
                                                FROM simulations
                                                INNER JOIN parameters USING(parameters_id)
                                                INNER JOIN games USING(game_id)
                                                INNER JOIN graphmodels USING(graph_id)
                                                WHERE simulations.group_id = $group_id
                                                LIMIT 1
                                        ")
    sim_info_df = DataFrame(query_sim_info)

    #query agents at each periods elapsed interval in the time series group
    query_agent_info = DBInterface.execute(db, "
                                                    SELECT
                                                        simulations.period,
                                                        agents.agent
                                                    FROM simulations
                                                    INNER JOIN agents USING(simulation_uuid)
                                                    WHERE simulations.group_id = $group_id
                                                    ORDER BY simulations.period ASC
                                                ")
    agent_df = DataFrame(query_agent_info)
    db_close(db)

    return (sim_info_df = sim_info_df, agent_df = agent_df)
end


function sql_query_simulations_for_noise_structure_heatmap(game_id::Integer,
                                                            number_agents::Integer,
                                                            memory_length::Integer,
                                                            errors_sql::String,
                                                            starting_condition::String,
                                                            stopping_condition::String,
                                                            graphmodel_params_sql::String,
                                                            sample_size::Integer
    )
    #ORDER BY parameters.error, graphmodels.λ
    """
    SELECT * FROM (
        SELECT
            ROW_NUMBER() OVER ( 
                PARTITION BY models.graphmodel_id, parameters.error, graphmodels.λ
                ORDER BY RANDOM()
            ) RowNum,
            simulations.uuid as simulation_uuid,
            parameters.error,
            simulations.period,
            graphmodels.id as graphmodel_id,
            graphmodels.display,
            graphmodels.type as graphmodel_type,
            graphmodels.graphmodel,
            graphmodels.λ,
            graphmodels.β,
            graphmodels.α,
            graphmodels.p_in,
            graphmodels.p_out,
            games.name
        FROM simulations
        INNER JOIN models ON simulations.model_id = models.id
        INNER JOIN parameters ON models.parameters_id = parameters.id
        INNER JOIN games ON models.game_id = games.id
        INNER JOIN graphmodels ON models.graphmodel_id = graphmodels.id
        WHERE simulations.complete = 1
        AND games.id = $game_id
        AND parameters.number_agents = $number_agents
        AND parameters.memory_length = $memory_length
        AND parameters.starting_condition = '$starting_condition'
        AND parameters.stopping_condition = '$stopping_condition'
        $errors_sql
        $graphmodel_params_sql
        )
    WHERE RowNum <= $sample_size;
    """
end

function execute_query_simulations_for_noise_structure_heatmap(db_info::SQLiteInfo;
                                                        game_id::Integer,
                                                        graphmodel_params::Vector{<:Dict{Symbol, Any}},
                                                        errors::Vector{<:AbstractFloat},
                                                        mean_degrees::Vector{<:AbstractFloat},
                                                        number_agents::Integer,
                                                        memory_length::Integer,
                                                        starting_condition::String,
                                                        stopping_condition::String,
                                                        sample_size::Integer)
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND parameters.error = $(errors[1])" : errors_sql *= "AND parameters.error IN $(Tuple(errors))"
    end
    mean_degrees_sql = ""
    if mean_degrees !== nothing
        length(mean_degrees) == 1 ? mean_degrees_sql *= "AND graphmodels.λ = $(mean_degrees[1])" : mean_degrees_sql *= "AND graphmodels.λ IN $(Tuple(mean_degrees))"
    end
    # graphmodel_params_sql = "AND ("
    # if graphmodel_params !== nothing
    #     for graph in graphmodel_params
    #         graphmodel_params_sql *= "("
    #         for (param, value) in graph
    #             graphmodel_params_sql *= "graphmodels.$(string(param)) = $(value === nothing ? "null" : value) AND "
    #         end
    #         graphmodel_params_sql = rstrip(graphmodel_params_sql, collect(" AND "))
    #         graphmodel_params_sql *= ") OR"
    #     end
    #     graphmodel_params_sql = rstrip(graphmodel_params_sql, collect(" OR"))
    #     graphmodel_params_sql *= ")"
    # end
    graphmodel_params_sql = "AND ("
    if graphmodel_params !== nothing
        for graph in graphmodel_params
            graphmodel_params_sql *= "("
            for (param, value) in graph
                graphmodel_params_sql *= "graphmodels.$(string(param)) = '$(value)' AND "
            end
            graphmodel_params_sql = rstrip(graphmodel_params_sql, collect(" AND "))
            graphmodel_params_sql *= ") OR "
        end
        graphmodel_params_sql = rstrip(graphmodel_params_sql, collect(" OR "))
        graphmodel_params_sql *= ")"
    end
    
    db = DB(db_info)
    println(sql_query_simulations_for_noise_structure_heatmap(game_id,
    number_agents,
    memory_length,
    errors_sql,
    starting_condition,
    stopping_condition,
    graphmodel_params_sql,
    sample_size))
    query = db_query(db, sql_query_simulations_for_noise_structure_heatmap(game_id,
                                                                            number_agents,
                                                                            memory_length,
                                                                            errors_sql,
                                                                            starting_condition,
                                                                            stopping_condition,
                                                                            graphmodel_params_sql,
                                                                            sample_size))
    db_close(db)
    return query

    # #error handling
    # errorsDF() = DataFrame(DBInterface.execute(db, "SELECT error FROM parameters"))
    # graphmodelsDF() = DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels"))
    # meanDegreesDF() = DataFrame(DBInterface.execute(db, "SELECT λ FROM graphmodels"))

    # error_set = []
    # errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    # graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing
    # mean_degrees === nothing ? mean_degrees = Set([λ for λ in numberAgentsDF()[:, :λ]]) : nothing


    # db_close(db)

    # for mean_degree in mean_degrees
    #     for error in errors
    #         for graph_id in graph_ids
    #             filtered_df = filter([:λ, :error, :graph_id] => (λ, err, id) -> λ == mean_degree && err == error && id == graph_id, df)
    #             if nrow(filtered_df) < sample_size
    #                 push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id, λ: $mean_degree]\n")
    #             end
    #         end
    #     end
    # end
    # if !isempty(error_set)
    #     errors_formatted = ""
    #     for err in error_set
    #         errors_formatted *= err
    #     end
    #     throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    # else
    #     return df
    # end
end


function query_simulations_for_transition_time_vs_graph_params_sweep(db_info::SQLiteInfo;
                                                                game_id::Integer,
                                                                memory_length::Integer,
                                                                number_agents::Integer,
                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                graph_params::Vector{<:Dict{Symbol, Any}},
                                                                starting_condition_id::Integer,
                                                                stopping_condition_id::Integer,
                                                                sample_size::Integer
    )    
                                                                                
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND parameters.error = $(errors[1])" : errors_sql *= "AND parameters.error IN $(Tuple(errors))"
    end
 
    graph_params_sql = "AND ("
    for graph in graph_params
        graph_params_sql *= "("
        for (param, value) in graph
            graph_params_sql *= "graphmodels.$(string(param)) = '$(value)' AND "
        end
        graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
        graph_params_sql *= ") OR"
    end
    graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
    graph_params_sql *= ")"


    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY simulations.graph_id, parameters.error
                                                    ORDER BY parameters.error
                                                ) RowNum,
                                                simulations.simulation_id,
                                                parameters.parameters,
                                                parameters.number_agents,
                                                parameters.memory_length,
                                                parameters.error,
                                                simulations.period,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                graphmodels.λ,
                                                graphmodels.β,
                                                graphmodels.α,
                                                graphmodels.p_in,
                                                graphmodels.p_out,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN parameters USING(parameters_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND parameters.number_agents = $number_agents
                                            $errors_sql
                                            $graph_params_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM parameters")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM parameters")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end