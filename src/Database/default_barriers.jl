"""
    DB(;kwargs...)

Create a connection to the configured database.
"""
DB(; kwargs...) = DB(Interactions.MAIN_DB(); kwargs...)
DB(::Nothing; kwargs...) = throw(NoDatabaseError())
"""
    sql(qp::QueryParams)

Generate a SQL query for a QueryParams instance (based on configured database type).
"""
sql(qp::QueryParams) = sql(Interactions.DATABASE(), qp)
sql(::Nothing, ::QueryParams) = throw(NoDatabaseError())
# function sql(qp::QueryParams)
#     if isempty(Interactions.SETTINGS.query)
#         return sql(Interactions.SETTINGS.database, qp)
#     else
#         return sql(Interactions.SETTINGS.query, qp)
#     end
# end


"""
    execute(sql::SQL)

Execute SQL (String) on the configured database.
"""
execute(sql::SQL) = execute(Interactions.MAIN_DB(), sql)
execute(::Nothing, ::SQL) = throw(NoDatabaseError())

"""
    query(sql::SQL)

Query the configured database using the SQL (String) provided. Returns a DataFrame containing results.
"""
query(sql::SQL) = query(Interactions.DATABASE(), sql)
query(::Nothing, ::SQL) = throw(NoDatabaseError())
# function query(sql::SQL)
#     if isempty(Interactions.SETTINGS.query)
#         return query(Interactions.SETTINGS.database, sql)
#     else
#         return query(Interactions.SETTINGS.query, sql)
#     end
# end


"""
    query(qp::QueryParams)

Query the configured database and attached databases using the QueryParams provided. Returns a DataFrame containing results.
"""
query(qp::QueryParams; kwargs...) = query(Interactions.DATABASE(), qp; kwargs...)
query(::Nothing, ::QueryParams) = throw(NoDatabaseError())

#query(qp::Query_simulations; ensure_samples::Bool=false) = query(Interactions.DATABASE(), qp; ensure_samples=ensure_samples)

query_timeseries(simulation_uuid::String, limit::Int) = query_timeseries(Interactions.DATABASE(), simulation_uuid, limit)

# begin_transaction() = begin_transaction(Interactions.SETTINGS.database)
# close(db::SQLiteDB) = SQLite.close(db)
# commit_transaction(db::SQLiteDB) = SQLite.commit(db)

init() = init(Interactions.MAIN_DB())
init(::Nothing) = throw(NoDatabaseError())


insert_group(description::String) = insert_group(Interactions.MAIN_DB(), description)
insert_group(::Nothing, ::String) = throw(NoDatabaseError())

insert_game(game::Types.Game) = insert_game(Interactions.MAIN_DB(), game)
insert_game(::Nothing, ::Types.Game) = throw(NoDatabaseError())

# insert_graphmodel(graphmodel::Types.GraphModel) = insert_graphmodel(Interactions.MAIN_DB(), graphmodel)
# insert_graphmodel(::Nothing, ::Types.GraphModel) = throw(NoDatabaseError())

insert_model(model::Types.Model; model_id::Union{Nothing, Integer}=nothing) = insert_model(Interactions.MAIN_DB(), model; model_id=model_id) #returns model_id::Int
insert_model(::Nothing, ::Types.Model; kwargs...) = throw(NoDatabaseError()) #NOTE: return nothing here instead of model_id since no database is configured. (do we want throw(NoDatabaseError()) instead?) could make custom NoDB type to return!
# try_insert_model(model::Model; model_id::Union{Nothing, Integer}=nothing) = insert_model(Interactions.MAIN_DB(), model, model_id=model_id)

insert_simulation(state::Types.State, sim_group_id::Union{Integer, Nothing} = nothing; full_store::Bool=true) = insert_simulation(Interactions.MAIN_DB(), state, sim_group_id; full_store=full_store)
insert_simulation(::Nothing, args...; kwargs...) = throw(NoDatabaseError())

has_incomplete_simulations() = has_incomplete_simulations(Interactions.MAIN_DB())
has_incomplete_simulations(::Nothing) = throw(NoDatabaseError())

get_incomplete_simulation_uuids() = get_incomplete_simulation_uuids(Interactions.MAIN_DB())
get_incomplete_simulation_uuids(::Nothing) = throw(NoDatabaseError())


collect_simulations(directory_path::String; kwargs...) = collect_simulations(Interactions.MAIN_DB(), directory_path; kwargs...)
collect_simulations(::Nothing, ::String) = throw(NoDatabaseError())


reconstruct_model(model_id::Integer) = reconstruct_model(Interactions.MAIN_DB(), model_id) #NOTE: want to have this search through all attached dbs
reconstruct_model(::Nothing, ::Integer) = throw(NoDatabaseError())

reconstruct_simulation(uuid::String) = reconstruct_simulation(Interactions.MAIN_DB(), uuid)
reconstruct_simulation(::Nothing, ::String) = throw(NoDatabaseError())