using LibPQ

const PostgresDB = LibPQ.Connection

DB(db_info::PostgresInfo) = LibPQ.Connection("dbname=$(db_info.name)
                                                user=$(db_info.user)
                                                host=$(db_info.host)
                                                port=$(db_info.port)
                                                password=$(db_info.password)")
db_close(db::PostgresDB) = db_close(db)
db_execute(db::PostgresDB, sql::String) = LibPQ.execute(db, sql)
db_query(db::PostgresDB, sql::String) = DataFrame(db_execute(db, sql))
                                                

function execute_init_db(db_info::PostgresInfo)
    #create or connect to database
    db = DB(db_info)

    #create 'games' table (currently only the "bargaining game" exists)
    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS games
                            (
                                game_id integer primary key generated always as identity,
                                game_name TEXT NOT NULL,
                                game TEXT NOT NULL,
                                payoff_matrix_size TEXT NOT NULL,
                                UNIQUE(game_name, game)
                            );
                    ")

    #create 'graphs' table which stores the graph types with their specific parameters (parameters might go in different table?)
    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS graphs
                            (
                                graph_id integer primary key generated always as identity,
                                graph TEXT NOT NULL,
                                graph_type TEXT NOT NULL,
                                graph_params TEXT NOT NULL,
                                λ REAL DEFAULT NULL,
                                β REAL DEFAULT NULL,
                                α REAL DEFAULT NULL,
                                blocks INTEGER DEFAULT NULL,
                                p_in REAL DEFAULT NULL,
                                p_out REAL DEFAULT NULL,
                                UNIQUE(graph, graph_params)
                            );
                    ")

    #create 'sim_params' table which contains information specific to each simulation
    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS sim_params
                            (
                                sim_params_id integer primary key generated always as identity,
                                number_agents INTEGER NOT NULL,
                                memory_length INTEGER NOT NULL,
                                error REAL NOT NULL,
                                sim_params TEXT NOT NULL,
                                use_seed BOOLEAN NOT NULL,
                                UNIQUE(sim_params, use_seed)
                            );
                    ")

    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS starting_conditions
                            (
                                starting_condition_id integer primary key generated always as identity,
                                name TEXT NOT NULL,
                                starting_condition TEXT NOT NULL,
                                UNIQUE(name, starting_condition)
                            );
                    ")

    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS stopping_conditions
                            (
                                stopping_condition_id integer primary key generated always as identity,
                                name TEXT NOT NULL,
                                stopping_condition TEXT NOT NULL,
                                UNIQUE(name, stopping_condition)
                            );
                    ")

    #create 'sim_groups' table to group simulations and give the groups an easy-access description (version control is handled with the prev_simulation_id column in the individual simulation saves)
    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS sim_groups
                            (
                                sim_group_id integer primary key generated always as identity,
                                description TEXT DEFAULT NULL,
                                UNIQUE(description)
                            );
                    ")

    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS models
                            (
                                model_id integer primary key generated always as identity,
                                game_id INTEGER NOT NULL,
                                graph_id INTEGER NOT NULL,
                                sim_params_id INTEGER NOT NULL,
                                starting_condition_id INTEGER NOT NULL,
                                stopping_condition_id INTEGER NOT NULL,
                                FOREIGN KEY (game_id)
                                    REFERENCES games (game_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (graph_id)
                                    REFERENCES graphs (graph_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (sim_params_id)
                                    REFERENCES sim_params (sim_params_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (starting_condition_id)
                                    REFERENCES starting_conditions (starting_condition_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (stopping_condition_id)
                                    REFERENCES stopping_conditions (stopping_condition_id)
                                    ON DELETE CASCADE,
                                UNIQUE(game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id)
                            )
                ")

#create 'simulations' table which contains information specific to each simulation
    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS simulations
                            (
                                simulation_id integer primary key generated always as identity,
                                simulation_uuid TEXT NOT NULL,
                                sim_group_id INTEGER DEFAULT NULL,
                                prev_simulation_uuid TEXT DEFAULT NULL,
                                model_id INTEGER NOT NULL,
                                graph_adj_matrix TEXT DEFAULT NULL,
                                rng_state TEXT NOT NULL,
                                periods_elapsed INTEGER NOT NULL,
                                FOREIGN KEY (sim_group_id)
                                    REFERENCES sim_groups (sim_group_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (prev_simulation_uuid)
                                    REFERENCES simulations (simulation_uuid),
                                FOREIGN KEY (model_id)
                                    REFERENCES models (model_id),
                                UNIQUE(simulation_uuid)
                            );
                    ")

    #create 'agents' table which contains json strings of agent types (with memory states). FK points to specific simulation
    db_execute(db, "
                            CREATE TABLE IF NOT EXISTS agents
                            (
                                agent_id integer primary key generated always as identity,
                                simulation_uuid TEXT NOT NULL,
                                agent TEXT NOT NULL,
                                FOREIGN KEY (simulation_uuid)
                                    REFERENCES simulations (simulation_uuid)
                                    ON DELETE CASCADE
                            );
                    ")
    db_close(db)
end

function execute_insert_game(db_info::PostgresInfo, game_name::String, game::String, payoff_matrix_size::String)
    db = DB(db_info)
    id::Int = db_query(db, "
                                    INSERT INTO games
                                    (
                                        game_name,
                                        game,
                                        payoff_matrix_size
                                    )
                                    VALUES
                                    (
                                        '$game_name',
                                        '$game',
                                        '$payoff_matrix_size'
                                    )
                                    ON CONFLICT (game_name, game) DO UPDATE
                                        SET game_name = games.game_name
                                    RETURNING game_id;
    ")[1, :game_id]
    db_close(db)
    return id
end

function execute_insert_graph(db_info::PostgresInfo, graph::String, graph_type::String, graph_params_str::String, db_graph_params_dict::Dict{Symbol, Any})
    db = DB(db_info)
    insert_string_columns = "graph, graph_type, graph_params, "
    insert_string_values = "'$graph', '$graph_type', '$graph_params_str', "
    for (param, value) in db_graph_params_dict
        if value !== nothing
            insert_string_columns *= "'$param', "
            insert_string_values *= "$value, "
        end
    end
    insert_string_columns = rstrip(insert_string_columns, [' ', ',']) #strip off the comma and space at the end of the string
    insert_string_values = rstrip(insert_string_values, [' ', ','])

    id::Int = db_query(db, "
                                    INSERT INTO graphs
                                    (
                                        $insert_string_columns
                                    )
                                    VALUES
                                    (
                                        $insert_string_values
                                    )
                                    ON CONFLICT (graph, graph_params) DO UPDATE
                                        SET graph_type = graphs.graph_type
                                    RETURNING graph_id;
    ")[1, :graph_id]
    db_close(db)
    return id
end

function execute_insert_sim_params(db_info::PostgresInfo, sim_params::SimParams, sim_params_str::String, use_seed::String)
    db = DB(db_info)
    id::Int = db_query(db, "
                                    INSERT INTO sim_params
                                    (
                                        number_agents,
                                        memory_length,
                                        error,
                                        sim_params,
                                        use_seed
                                    )
                                    VALUES
                                    (
                                        $(sim_params.number_agents),
                                        $(sim_params.memory_length),
                                        $(sim_params.error),
                                        '$sim_params_str',
                                        '$use_seed'
                                    )
                                    ON CONFLICT (sim_params, use_seed) DO UPDATE
                                        SET use_seed = sim_params.use_seed
                                    RETURNING sim_params_id;
    ")[1, :sim_params_id]
    db_close(db)
    return id
end

function execute_insert_starting_condition(db_info::PostgresInfo, starting_condition_name::String, starting_condition_str::String)
    db = DB(db_info)
    id::Int = db_query(db, "
                                    INSERT INTO starting_conditions
                                    (
                                        name,
                                        starting_condition
                                    )
                                    VALUES
                                    (
                                        '$starting_condition_name',
                                        '$(starting_condition_str)'
                                    )
                                    ON CONFLICT (name, starting_condition) DO UPDATE
                                        SET name = starting_conditions.name
                                    RETURNING starting_condition_id;
    ")[1, :starting_condition_id]
    db_close(db)
    return id
end

function execute_insert_stopping_condition(db_info::PostgresInfo, stopping_condition_name::String, stopping_condition_str::String)
    db = DB(db_info)
    id::Int = db_query(db, "
                                    INSERT INTO stopping_conditions
                                    (
                                        name,
                                        stopping_condition
                                    )
                                    VALUES
                                    (
                                        '$stopping_condition_name',
                                        '$(stopping_condition_str)'
                                    )
                                    ON CONFLICT (name, stopping_condition) DO UPDATE
                                        SET name = stopping_conditions.name
                                    RETURNING stopping_condition_id;
    ")[1, :stopping_condition_id]
    db_close(db)
    return id
end

function execute_insert_sim_group(db_info::PostgresInfo, description::String)
    db = DB(db_info)
    id::Int = db_query(db, "
                                    INSERT INTO sim_groups
                                    (
                                        description
                                    )
                                    VALUES
                                    (
                                        '$description'
                                    )
                                    ON CONFLICT (description) DO UPDATE
                                        SET description = sim_groups.description
                                    RETURNING sim_group_id;
    ")[1, :sim_group_id]
    db_close(db)
    return id
end


function execute_insert_simulation(db_info::PostgresInfo, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, db_id_tuple::DatabaseIdTuple, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer, agent_list::Vector{String})
    simulation_uuid = "$(uuid4())"
    
    #prepare simulation SQL
    sim_group_id === nothing ? sim_group_id = "NULL" : nothing
    prev_simulation_uuid = prev_simulation_uuid === nothing ?  "null" : "'$prev_simulation_uuid'"

    #prepare agents SQL
    agent_values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        agent_values_string *= "('$simulation_uuid', '$agent'), "
    end
    agent_values_string = rstrip(agent_values_string, [' ', ','])

    #open DB connection
    db = DB(db_info)

    #first insert simulation with simulation_uuid
    result = LibPQ.execute(db, "
                                    INSERT INTO simulations
                                    (
                                        simulation_uuid,
                                        sim_group_id,
                                        prev_simulation_uuid,
                                        game_id,
                                        graph_id,
                                        sim_params_id,
                                        starting_condition_id,
                                        stopping_condition_id,
                                        graph_adj_matrix,
                                        rng_state,
                                        periods_elapsed
                                    )
                                    VALUES
                                    (
                                        '$simulation_uuid',
                                        $sim_group_id,
                                        $prev_simulation_uuid,
                                        $(db_id_tuple.game_id),
                                        $(db_id_tuple.graph_id),
                                        $(db_id_tuple.sim_params_id),
                                        $(db_id_tuple.starting_condition_id),
                                        $(db_id_tuple.stopping_condition_id),
                                        '$graph_adj_matrix_str',
                                        '$rng_state',
                                        $periods_elapsed
                                    );

                                    INSERT INTO agents
                                    (
                                        simulation_uuid,
                                        agent
                                    )
                                    VALUES
                                        $agent_values_string;
                            ")

    db_close(db)

    return (status_message = "PostgreSQL [SimulationSaves: simulations & agents]... SIMULATION INSERT STATUS: [OK] AGENTS INSERT STATUS: [OK] SIMULATION_UUID: [$simulation_uuid]", simulation_uuid = simulation_uuid)
end










function execute_query_games(db_info::PostgresInfo, game_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM games
                                        WHERE game_id = $game_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_graphs(db_info::PostgresInfo, graph_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM graphs
                                        WHERE graph_id = $graph_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_sim_params(db_info::PostgresInfo, sim_params_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM sim_params
                                        WHERE sim_params_id = $sim_params_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_starting_conditions(db_info::PostgresInfo, starting_condition_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM starting_conditions
                                        WHERE starting_condition_id = $starting_condition_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_stopping_conditions(db_info::PostgresInfo, stopping_condition_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM stopping_conditions
                                        WHERE stopping_condition_id = $stopping_condition_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_sim_groups(db_info::PostgresInfo, sim_group_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM sim_groups
                                        WHERE sim_group_id = $sim_group_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_simulations(db_info::PostgresInfo, simulation_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM simulations
                                        WHERE simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_agents(db_info::PostgresInfo, simulation_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT *
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_simulations_for_restore(db_info::PostgresInfo, simulation_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT
                                            simulations.simulation_id,
                                            simulations.sim_group_id,
                                            sim_params.sim_params,
                                            sim_params.use_seed,
                                            simulations.rng_state,
                                            simulations.periods_elapsed,
                                            simulations.graph_adj_matrix,
                                            graphs.graph_params,
                                            games.game,
                                            games.payoff_matrix_size,
                                            starting_conditions.starting_condition,
                                            stopping_conditions.stopping_condition
                                        FROM simulations
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphs USING(graph_id)
                                        INNER JOIN sim_params USING(sim_params_id)
                                        INNER JOIN starting_conditions USING(starting_condition_id)
                                        INNER JOIN stopping_conditions USING(stopping_condition_id)
                                        WHERE simulations.simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_agents_for_restore(db_info::PostgresInfo, simulation_id::Integer)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT agent
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end


#NOTE: FIX
# function querySimulationsByGroup(db_info::PostgresInfo, sim_group_id::Int)
#     db = DB(db_info)
#   
#     query = LibPQ.execute(db, "
#                                         SELECT
#                                             simulations.simulation_id,
#                                             simulations.sim_group_id,
#                                             simulations.sim_params_id,
#                                             simulations.graph_adj_matrix,
#                                             simulations.use_seed,
#                                             simulations.rng_state,
#                                             simulations.periods_elapsed,
#                                             games.game,
#                                             games.payoff_matrix_size,
#                                             graphs.graph_params
#                                         FROM simulations
#                                         INNER JOIN games USING(game_id)
#                                         INNER JOIN graphs USING(graph_id)
#                                         INNER JOIN sim_params USING(sim_params_id)
#                                         WHERE simulations.sim_group_id = $sim_group_id
#                                 ")
#     df = DataFrame(query) #must create a DataFrame to acces query data
#     db_close(db)
#     return df
# end

#this function allows for RAM space savings during large iterative simulations
function querySimulationIDsByGroup(db_info::PostgresInfo, sim_group_id::Int)
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT
                                            simulation_id
                                        FROM simulations
                                        WHERE sim_group_id = $sim_group_id
                                        ORDER BY simulation_id ASC
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_delete_simulation(db_info::PostgresInfo, simulation_id::Int)
    db = DB(db_info)
    LibPQ.execute(db, "PRAGMA foreign_keys = ON;") #turn on foreign key support to allow cascading deletes
    status = LibPQ.execute(db, "DELETE FROM simulations WHERE simulation_id = $simulation_id;")
    db_close(db)
    return status
end


function querySimulationsForBoxPlot(db_info::PostgresInfo; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Int)
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY graph_id
                                                    ORDER BY graph_id, simulation_id
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.number_agents = $number_agents
                                            AND sim_params.memory_length = $memory_length
                                            AND sim_params.error = $error
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
        throw(ErrorException("Not enough samples for the following graphs: $error_set"))
    else
        return df
    end
end


function querySimulationsForMemoryLengthLinePlot(db_info::PostgresInfo; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
    memory_lengths_sql = ""
    if memory_length_list !== nothing
        length(memory_length_list) == 1 ? memory_lengths_sql *= "AND sim_params.memory_length = $(memory_length_list[1])" : memory_lengths_sql *= "AND sim_params.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end


    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.memory_length, sim_params.error, simulations.graph_id
                                                    ORDER BY sim_params.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.number_agents = $number_agents
                                            $memory_lengths_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)


    #error handling
    function memoryLengthsDF() DataFrame(LibPQ.execute(db, "SELECT memory_length FROM sim_params")) end
    function errorsDF() DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params")) end
    function graphsDF() DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    memory_length_list === nothing ? memory_length_list = Set([memory_length for memory_length in memoryLengthsDF()[:, :memory_length]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

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




function querySimulationsForNumberAgentsLinePlot(db_info::PostgresInfo; game_id::Integer, number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing, memory_length::Integer, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
    number_agents_sql = ""
    if number_agents_list !== nothing
        length(number_agents_list) == 1 ? number_agents_sql *= "AND sim_params.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND sim_params.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end


    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.number_agents, sim_params.error, simulations.graph_id
                                                    ORDER BY sim_params.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.memory_length = $memory_length
                                            $number_agents_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)


    #error handling
    function numberAgentsDF() DataFrame(LibPQ.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params")) end
    function graphsDF() DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

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


function query_simulations_for_transition_time_vs_memory_sweep(db_info::PostgresInfo;
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
        length(memory_length_list) == 1 ? memory_length_sql *= "AND sim_params.memory_length = $(memory_length_list[1])" : memory_length_sql *= "AND sim_params.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end

    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.memory_length, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.number_agents = $number_agents
                                            $memory_length_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(LibPQ.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params")) end
    function graphsDF() DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

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



function query_simulations_for_transition_time_vs_population_sweep(db_info::PostgresInfo;
                                                                    game_id::Integer,
                                                                    number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                    memory_length::Integer,
                                                                    errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                    graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                    starting_condition_id::Integer,
                                                                    stopping_condition_id::Integer,
                                                                    sample_size::Integer)    
                                                                                
    number_agents_sql = ""
    if number_agents_list !== nothing
        length(number_agents_list) == 1 ? number_agents_sql *= "AND sim_params.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND sim_params.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end

    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.number_agents, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                graphs.λ,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.memory_length = $memory_length
                                            $number_agents_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(LibPQ.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params")) end
    function graphsDF() DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

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


function query_simulations_for_transition_time_vs_population_stopping_condition(db_info::PostgresInfo;
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
        length(number_agents_list) == 1 ? number_agents_sql *= "AND sim_params.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND sim_params.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
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

    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.number_agents, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.memory_length = $memory_length
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
    function numberAgentsDF() DataFrame(LibPQ.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params")) end
    function graphsDF() DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

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



function query_simulations_for_transition_time_vs_memory_length_stopping_condition(db_info::PostgresInfo;
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
        length(memory_length_list) == 1 ? memory_lengths_sql *= "AND sim_params.memory_length = $(memory_length_list[1])" : memory_lengths_sql *= "AND sim_params.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
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

    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.memory_length, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.number_agents = $number_agents
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
    function numberAgentsDF() DataFrame(LibPQ.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params")) end
    function graphsDF() DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

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



function querySimulationsForTimeSeries(db_info::PostgresInfo;sim_group_id::Integer)
    db = DB(db_info)

    #query the simulation info (only need one row since each entry in the timeseries group will have the same info)
    #separate this from agent query to save memory, as this query could be very memory intensive
    query_sim_info = LibPQ.execute(db, "
                                                SELECT
                                                    simulations.simulation_id,
                                                    sim_params.sim_params,
                                                    sim_params.number_agents,
                                                    sim_params.memory_length,
                                                    sim_params.error,
                                                    graphs.graph_id,
                                                    graphs.graph,
                                                    graphs.graph_params,
                                                    games.game_name,
                                                    games.game,
                                                    games.payoff_matrix_size
                                                FROM simulations
                                                INNER JOIN sim_params USING(sim_params_id)
                                                INNER JOIN games USING(game_id)
                                                INNER JOIN graphs USING(graph_id)
                                                WHERE simulations.sim_group_id = $sim_group_id
                                                LIMIT 1
                                        ")
    sim_info_df = DataFrame(query_sim_info)

    #query agents at each periods elapsed interval in the time series group
    query_agent_info = LibPQ.execute(db, "
                                                    SELECT
                                                        simulations.periods_elapsed,
                                                        agents.agent
                                                    FROM simulations
                                                    INNER JOIN agents USING(simulation_uuid)
                                                    WHERE simulations.sim_group_id = $sim_group_id
                                                    ORDER BY simulations.periods_elapsed ASC
                                                ")
    agent_df = DataFrame(query_agent_info)
    db_close(db)

    return (sim_info_df = sim_info_df, agent_df = agent_df)
end




function query_simulations_for_noise_structure_heatmap(db_info::PostgresInfo;
                                                        game_id::Integer,
                                                        graph_params::Vector{<:Dict{Symbol, Any}},
                                                        errors::Vector{<:AbstractFloat},
                                                        mean_degrees::Vector{<:AbstractFloat},
                                                        number_agents::Integer,
                                                        memory_length::Integer,
                                                        starting_condition_id::Integer,
                                                        stopping_condition_id::Integer,
                                                        sample_size::Integer)
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    mean_degrees_sql = ""
    if mean_degrees !== nothing
        length(mean_degrees) == 1 ? mean_degrees_sql *= "AND graphs.λ = $(mean_degrees[1])" : mean_degrees_sql *= "AND graphs.λ IN $(Tuple(mean_degrees))"
    end
    # graph_params_sql = "AND ("
    # if graph_params !== nothing
    #     for graph in graph_params
    #         graph_params_sql *= "("
    #         for (param, value) in graph
    #             graph_params_sql *= "graphs.$(string(param)) = $(value === nothing ? "null" : value) AND "
    #         end
    #         graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
    #         graph_params_sql *= ") OR"
    #     end
    #     graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
    #     graph_params_sql *= ")"
    # end
    graph_params_sql = "AND ("
    if graph_params !== nothing
        for graph in graph_params
            graph_params_sql *= "("
            for (param, value) in graph
                graph_params_sql *= "graphs.$(string(param)) = '$(value)' AND "
            end
            graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
            graph_params_sql *= ") OR"
        end
        graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
        graph_params_sql *= ")"
    end
    
    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY simulations.graph_id, sim_params.error, graphs.λ
                                                    ORDER BY sim_params.error, graphs.λ
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_type,
                                                graphs.graph_params,
                                                graphs.λ,
                                                graphs.β,
                                                graphs.α,
                                                graphs.p_in,
                                                graphs.p_out,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.number_agents = $number_agents
                                            AND sim_params.memory_length = $memory_length
                                            $errors_sql
                                            $graph_params_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)
    println(df)
    return df

    # #error handling
    # errorsDF() = DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params"))
    # graphsDF() = DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs"))
    # meanDegreesDF() = DataFrame(LibPQ.execute(db, "SELECT λ FROM graphs"))

    # error_set = []
    # errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    # graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing
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


function query_simulations_for_transition_time_vs_graph_params_sweep(db_info::PostgresInfo;
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
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
 
    graph_params_sql = "AND ("
    for graph in graph_params
        graph_params_sql *= "("
        for (param, value) in graph
            graph_params_sql *= "graphs.$(string(param)) = '$(value)' AND "
        end
        graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
        graph_params_sql *= ") OR"
    end
    graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
    graph_params_sql *= ")"


    db = DB(db_info)
    query = LibPQ.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY simulations.graph_id, sim_params.error
                                                    ORDER BY sim_params.error
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                graphs.λ,
                                                graphs.β,
                                                graphs.α,
                                                graphs.p_in,
                                                graphs.p_out,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.number_agents = $number_agents
                                            $errors_sql
                                            $graph_params_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(LibPQ.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(LibPQ.execute(db, "SELECT error FROM sim_params")) end
    function graphsDF() DataFrame(LibPQ.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

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