"""
    sql(db::SQLiteInfo, qp::QueryParams)

Generate a SQL query for a QueryParams instance (based on SQLite).
"""
function sql(db_info::SQLiteInfo, qp::QueryParams, db_name::String="main") #for games, parameters, and graphmodels
    filter_str = sql_filter(db_info, qp, db_name)
    if !isempty(filter_str)
        filter_str = " WHERE " * filter_str
    end
    return """
            SELECT
                *,
                '$db_name' as db_name
                FROM $db_name.$(table(qp))
                $filter_str
            """
end

function sql(db_info::SQLiteInfo, qp::Union{Query_graphmodels, Query_GraphModel}, db_name::String="main") #for games, parameters, and graphmodels
    filter_str = sql_filter(db_info, qp, db_name)
    if !isempty(filter_str)
        filter_str = " WHERE " * filter_str
    end
    return """
            SELECT DISTINCT 
                $db_name.graphmodels.id,
                $db_name.graphmodels.name,
                $db_name.graphmodels.display,
                $db_name.graphmodels.params,
                $db_name.graphmodels.kwargs,
                '$db_name' as db_name
            FROM $db_name.graphmodels
            LEFT JOIN $db_name.graphmodel_parameters ON $db_name.graphmodel_parameters.graphmodel_id = $db_name.graphmodels.id
            $filter_str
            """
end

"""
    sql(dbs::Vector{SQLiteInfo}, qp::QueryParams)

Generate a SQL query across all databases in 'dbs' for a QueryParams instance (based on SQLite).
"""
function sql(db_info::Vector{SQLiteInfo}, qp::QueryParams) #for games, parameters, and graphmodels, and models 
    @assert !isempty(db_info) "db_info Vector is empty"                                                           
    union_str = ""
    for db in db_info[2:end]
        union_str *= " UNION ALL " * sql(db, qp, db.name)
    end
    # distinct = "model_id, game_id, parameters_id, graphmodel_id, game_bin, parameters, graphmodel"
    # println("SELECT DISTINCT * FROM (" * sql(db_info[1], qp, filter_str, "main") * union_str * ")")
    return  sql(db_info[1], qp) * union_str
end


"""
    sql(db::SQLiteInfo, qp::Query_models)

Generate a SQL query for a Query_models instance (based on SQLite).
"""
function sql(db_info::SQLiteInfo, qp::Query_models, db_name::String="main")
    filter_str = sql_filter(db_info, qp, db_name)
    # if !isempty(filter_str)
    #     filter_str = " WHERE " * filter_str
    # end

    """
    SELECT
        models.id as model_id,
        models.game_id,
        models.parameters_id,
        models.graphmodel_id,
        games.name,
        games.game_bin,
        parameters.number_agents,
        parameters.memory_length,
        parameters.error,
        parameters.starting_condition,
        parameters.stopping_condition,
        parameters.parameters,
        graphmodels.name as graphmodel_name,
        graphmodels.display as graphmodel_display,
        graphmodels.params as graphmodel_params,
        graphmodels.kwargs as graphmodel_kwargs,
        '$db_name' as db_name
    FROM $db_name.models
    INNER JOIN $db_name.parameters ON $db_name.models.parameters_id = $db_name.parameters.id
    INNER JOIN $db_name.games ON $db_name.models.game_id = $db_name.games.id
    INNER JOIN $db_name.graphmodels ON $db_name.models.graphmodel_id = $db_name.graphmodels.id
    LEFT JOIN $db_name.graphmodel_parameters ON $db_name.graphmodel_parameters.graphmodel_id = $db_name.graphmodels.id
    $filter_str
    """
end



"""
    sql(db::SQLiteInfo, qp::Query_simulations)

Generate a SQL query for a Query_simulations instance (based on SQLite).
"""
function sql(db_info::SQLiteInfo, qp::Query_simulations, inner_str::String=sql_inner(db_info, qp)) #NOTE: sql_inner is no longer called like this! fix! #NOTE: do we just want to return *?
    """
    SELECT * FROM (
        SELECT
            ROW_NUMBER() OVER ( 
                    PARTITION BY number_agents,
                                 memory_length,
                                 error,
                                 starting_condition,
                                 stopping_condition

                    ORDER BY $(!iszero(qp.sample_size) ? "RANDOM()" : "(SELECT NULL)")
            ) RowNum,
            db_name,
            number_agents,
            memory_length,
            error,
            starting_condition,
            stopping_condition,
            graphmodel_name,
            graphmodel_display,
            graphmodel_params,
            graphmodel_kwargs,
            uuid as simulation_uuid,
            period,
            complete
        FROM ($inner_str)
        $(!isnothing(qp.complete) ? "WHERE complete = $(Int(qp.complete))" : "")
    )
    $(!iszero(qp.sample_size) ? "WHERE RowNum <= $(qp.sample_size)" : "")
    """
end


"""
    sql(dbs::Vector{SQLiteInfo}, qp::Query_simulations)

Generate a SQL query across all databases in 'dbs' for a Query_simulations instance (based on SQLite).
"""
function sql(db_info::Vector{SQLiteInfo}, qp::Query_simulations)
    @assert !isempty(db_info) "db_info Vector is empty"

    # function sql_inner(db_name::String)
    #     filter_str = sql_filter(db_info[1], qp.model, db_name)
    #     """
    #     SELECT
    #         simulations.uuid,
    #         simulations.prev_simulation_uuid,
    #         simulations.complete,
    #         simulations.period,
    #         simulations.data,
    #         simulations.rng_state,
    #         simulations.random_seed,
    #         simulations.graph_adj_matrix,
    #         simulations.user_variables,
    #         models.id as model_id,
    #         models.game_id,
    #         models.parameters_id,
    #         models.graphmodel_id,
    #         games.name as game_name,
    #         games.game_bin,
    #         parameters.number_agents,
    #         parameters.memory_length,
    #         parameters.error,
    #         parameters.starting_condition,
    #         parameters.stopping_condition,
    #         parameters.parameters,
    #         graphmodels.name as graphmodel_name,
    #         graphmodels.display as graphmodel_display,
    #         graphmodels.params as graphmodel_params,
    #         graphmodels.kwargs as graphmodel_kwargs,
    #         '$db_name' as db_name
    #     FROM $db_name.simulations
    #     INNER JOIN $db_name.models ON $db_name.simulations.model_id = $db_name.models.id
    #     INNER JOIN $db_name.parameters ON $db_name.models.parameters_id = $db_name.parameters.id
    #     INNER JOIN $db_name.games ON $db_name.models.game_id = $db_name.games.id
    #     INNER JOIN $db_name.graphmodels ON $db_name.models.graphmodel_id = $db_name.graphmodels.id
    #     LEFT JOIN $db_name.graphmodel_parameters ON $db_name.graphmodel_parameters.graphmodel_id = $db_name.graphmodels.id
    #     $filter_str
    #     """
    # end

    inner_str = sql_inner(db_info[1], qp)
    for db in db_info[2:end]
        inner_str *= " UNION ALL " * sql_inner(db, qp, db.name)
    end
    return sql(db_info[1], qp, inner_str)
end

function sql_inner(db_info::SQLiteInfo, qp::Query_simulations, db_name::String="main")
    filter_str = sql_filter(db_info, qp.model, db_name)
    """
    SELECT
        simulations.uuid,
        simulations.prev_simulation_uuid,
        simulations.complete,
        simulations.period,
        simulations.data,
        simulations.rng_state,
        simulations.random_seed,
        simulations.graph_adj_matrix,
        simulations.user_variables,
        models.id as model_id,
        models.game_id,
        models.parameters_id,
        models.graphmodel_id,
        games.name as game_name,
        games.game_bin,
        parameters.number_agents,
        parameters.memory_length,
        parameters.error,
        parameters.starting_condition,
        parameters.stopping_condition,
        parameters.parameters,
        graphmodels.name as graphmodel_name,
        graphmodels.display as graphmodel_display,
        graphmodels.params as graphmodel_params,
        graphmodels.kwargs as graphmodel_kwargs,
        '$db_name' as db_name
    FROM $db_name.simulations
    INNER JOIN $db_name.models ON $db_name.simulations.model_id = $db_name.models.id
    INNER JOIN $db_name.parameters ON $db_name.models.parameters_id = $db_name.parameters.id
    INNER JOIN $db_name.games ON $db_name.models.game_id = $db_name.games.id
    INNER JOIN $db_name.graphmodels ON $db_name.models.graphmodel_id = $db_name.graphmodels.id
    LEFT JOIN $db_name.graphmodel_parameters ON $db_name.graphmodel_parameters.graphmodel_id = $db_name.graphmodels.id
    $filter_str
    """
end


"""
    sql(db_info::DatabaseSettings{SQLiteInfo}, qp::QueryParams)

Generate a SQL query across the main and attached databases in 'db_info' for a QueryParams instance (based on SQLite).
"""
sql(db_info::DatabaseSettings{SQLiteInfo}, qp::QueryParams) = sql([main(db_info), attached(db_info)...], qp) #forwards to respecitive ::Vector{SQLiteInfo} methods





function sql_filter(::SQLiteInfo, qp::Query_games, db_name::String="main")
    filter_str = ""
    if length(qp.name) == 1
        filter_str = "($db_name.$(table(qp)).name = '$(qp.name[1])')"
    elseif !isempty(qp.name)
        filter_str = "($db_name.$(table(qp)).name IN $(Tuple(qp.name)))"
    end
    return filter_str
end


function sql_filter(::SQLiteInfo, qp::Query_parameters, db_name::String="main")
    filter_str = ""
    for field in fieldnames(typeof(qp))
        vals = getfield(qp, field)
        if isempty(vals)
            continue
        elseif length(vals) == 1
            filter_str *= "$db_name.$(table(qp)).$(string(field)) = '$(vals[1])' AND "
        else
            filter_str *= "$db_name.$(table(qp)).$(string(field)) IN $(Tuple(vals)) AND "
        end
    end
    if !isempty(filter_str)
        filter_str = "(" * chop(filter_str, tail=5) * ")"
    end
    return filter_str
end

# function sql_filter(::SQLiteInfo, qp::Query_GraphModel, db_name::String="main")
#     filter_str = "$(table(qp)).type = '$(type(qp))' AND "
#     for field in fieldnames(typeof(qp))
#         vals = getfield(qp, field)
#         if isempty(vals)
#             continue
#         elseif length(vals) == 1
#             filter_str *= "$db_name.$(table(qp)).$(string(field)) = '$(vals[1])' AND "
#         else
#             filter_str *= "$db_name.$(table(qp)).$(string(field)) IN $(Tuple(vals)) AND "
#         end
#     end
#     if !isempty(filter_str)
#         filter_str = "(" * chop(filter_str, tail=5) * ")"
#     end
#     return filter_str
# end

function sql_filter(::SQLiteInfo, qp::Query_GraphModel, db_name::String="main")
    filter_str = "$db_name.graphmodels.name = '$(name(qp))' AND "
    for (field, vals) in pairs(params(qp))
        # println(field)
        # println(vals)
        if isempty(vals)
            continue
        elseif length(vals) == 1
            filter_str *= "($db_name.graphmodel_parameters.name = '$(string(field))' AND $db_name.graphmodel_parameters.value = '$(vals[1])') AND "
        else
            filter_str *= "($db_name.graphmodel_parameters.name = '$(string(field))' AND $db_name.graphmodel_parameters.value IN $(Tuple(vals))) AND "
        end
    end
    if !isempty(filter_str)
        filter_str = "(" * chop(filter_str, tail=5) * ")"
    end
    return filter_str
end

function sql_filter(db_info::SQLiteInfo, qp::Query_graphmodels, db_name::String="main")
    filter_str = ""
    for graphmodel in qp.graphmodels
        temp_str = sql_filter(db_info, graphmodel, db_name)
        if !isempty(temp_str)
            temp_str *= " OR "
        end
        filter_str *= temp_str
    end
    return "(" * chop(filter_str, tail=4) * ")"
end



function sql_filter(db_info::SQLiteInfo, qp::Query_models, db_name::String="main") #NOTE: refactor
    filter_str = ""
    games_filter_str = sql_filter(db_info, qp.games, db_name)
    if !isempty(games_filter_str)
        games_filter_str *= " AND "
    end
    filter_str *= games_filter_str
    parameters_filter_str = sql_filter(db_info, qp.parameters, db_name)
    if !isempty(parameters_filter_str)
        parameters_filter_str *= " AND "
    end
    filter_str *= parameters_filter_str
    graphmodels_filter_str = sql_filter(db_info, qp.graphmodels, db_name)
    if !isempty(graphmodels_filter_str)
        graphmodels_filter_str *= " AND "
    end
    filter_str *= graphmodels_filter_str
    if !isempty(filter_str)
        filter_str = "WHERE " * chop(filter_str, tail=5)
    end
    return filter_str
end




#NOTE: OLD
# function sql(::SQLiteInfo, qp::Query_simulations, db_name::String) #NOTE: default db_name is main, but this could cause issues if used incorrectly
#     # WITH CTE_models AS (
#     #     $(sql(db_info, qp.model, db_name))
#     # )

#     #, CTE_models.db_name
#     """
#     SELECT * FROM (
#         SELECT
#             ROW_NUMBER() OVER ( 
#                     PARTITION BY CTE_models.model_id, CTE_models.db_name
#                     ORDER BY $(!iszero(qp.sample_size) ? "RANDOM()" : "(SELECT NULL)")
#             ) RowNum,
#             CTE_models.model_id,
#             CTE_models.game_id,
#             CTE_models.parameters_id,
#             CTE_models.graphmodel_id,
#             CTE_models.number_agents,
#             CTE_models.memory_length,
#             CTE_models.error,
#             CTE_models.starting_condition,
#             CTE_models.stopping_condition,
#             CTE_models.graphmodel_type,
#             CTE_models.graphmodel_display,
#             CTE_models.λ,
#             CTE_models.β,
#             CTE_models.α,
#             CTE_models.blocks,
#             CTE_models.p_in,
#             CTE_models.p_out,
#             CTE_models.db_name,
#             simulations.uuid as simulation_uuid,
#             simulations.period,
#             simulations.complete
#         FROM $db_name.simulations
#         INNER JOIN CTE_models ON $db_name.simulations.model_id = CTE_models.model_id
#         WHERE CTE_models.db_name = '$db_name'
#         $(!isnothing(qp.complete) ? "AND complete = $(Int(qp.complete))" : "")
#     )
#     $(!iszero(qp.sample_size) ? "WHERE RowNum <= $(qp.sample_size)" : "")
#     """
# end

