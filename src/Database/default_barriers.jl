"""
    DB(;kwargs...)

Create a connection to the configured database.
"""
DB(; kwargs...) = DB(Interactions.MAIN_DB(); kwargs...)
DB(::Nothing; kwargs...) = _nodb()
"""
    sql(qp::QueryParams)

Generate a SQL query for a QueryParams instance (based on configured database type).
"""
sql(qp::QueryParams) = sql(Interactions.DATABASE(), qp)
sql(::Nothing, ::QueryParams) = _nodb()
# function sql(qp::QueryParams)
#     if isempty(Interactions.SETTINGS.query)
#         return sql(Interactions.SETTINGS.database, qp)
#     else
#         return sql(Interactions.SETTINGS.query, qp)
#     end
# end


"""
    db_execute(sql::SQL)

Execute SQL (String) on the configured database.
"""
db_execute(sql::SQL) = db_execute(Interactions.MAIN_DB(), sql)
db_execute(::Nothing, ::SQL) = _nodb()

"""
    db_query(sql::SQL)

Query the configured database using the SQL (String) provided. Returns a DataFrame containing results.
"""
db_query(sql::SQL) = db_query(Interactions.DATABASE(), sql)
db_query(::Nothing, ::SQL) = _nodb()
# function db_query(sql::SQL)
#     if isempty(Interactions.SETTINGS.query)
#         return db_query(Interactions.SETTINGS.database, sql)
#     else
#         return db_query(Interactions.SETTINGS.query, sql)
#     end
# end


"""
    db_query(qp::QueryParams)

Query the configured database and attached databases using the QueryParams provided. Returns a DataFrame containing results.
"""
db_query(qp::QueryParams; kwargs...) = db_query(Interactions.DATABASE(), qp; kwargs...)
db_query(::Nothing, ::QueryParams) = _nodb()

#db_query(qp::Query_simulations; ensure_samples::Bool=false) = db_query(Interactions.DATABASE(), qp; ensure_samples=ensure_samples)

# db_begin_transaction() = db_begin_transaction(Interactions.SETTINGS.database)
# db_close(db::SQLiteDB) = SQLite.close(db)
# db_commit_transaction(db::SQLiteDB) = SQLite.commit(db)

db_init() = db_init(Interactions.MAIN_DB())
db_init(::Nothing) = _nodb()


db_insert_sim_group(description::String) = db_insert_sim_group(Interactions.MAIN_DB(), description)
db_insert_sim_group(::Nothing, ::String) = _nodb()

db_insert_game(game::Game) = db_insert_game(Interactions.MAIN_DB(), game)
db_insert_game(::Nothing, ::Game) = _nodb()

db_insert_graphmodel(graphmodel::GraphModel) = db_insert_graphmodel(Interactions.MAIN_DB(), graphmodel)
db_insert_graphmodel(::Nothing, ::GraphModel) = _nodb()

db_insert_parameters(params::Parameters, use_seed::Bool) = db_insert_parameters(Interactions.MAIN_DB(), params, use_seed)
db_insert_parameters(::Nothing, ::Parameters, ::Bool) = _nodb()


db_insert_model(model::Model; model_id::Union{Nothing, Integer}=nothing) = db_insert_model(Interactions.MAIN_DB(), model, model_id=model_id)
db_insert_model(::Nothing, ::Model) = _nodb()

db_insert_simulation(state::State, model_id::Integer, sim_group_id::Union{Integer, Nothing} = nothing) = db_insert_simulation(Interactions.MAIN_DB(), state, model_id, sim_group_id; full_store=Interactions.DATABASE().full_store)
db_insert_simulation(::Nothing, args...) = _nodb()

db_has_incomplete_simulations() = db_has_incomplete_simulations(Interactions.MAIN_DB())
db_has_incomplete_simulations(::Nothing) = _nodb()

db_collect_temp(directory_path::String; kwargs...) = db_collect_temp(Interactions.MAIN_DB(), directory_path; kwargs...)
db_collect_temp(::Nothing, ::String) = _nodb()