module Database

import
    ..Types,
    ..GraphsExt,
    ..Interactions

using
    # ..Interactions,
    DataFrames,
    JSON3,
    UUIDs,
    Serialization

abstract type DBInfo end

struct PostgresInfo <: DBInfo
    name::String
    user::String
    host::String
    port::String
    password::String
end

struct SQLiteInfo <: DBInfo
    name::String
    filepath::String

    function SQLiteInfo(name::String, filepath::String)
        @assert !isempty(name) "'name' cannot be empty"
        @assert !isempty(filepath) "'filepath' cannot be empty" #actually want to ensure that filepath exists
        return new(name, filepath)
    end
end

type(database::SQLiteInfo) = "sqlite"
type(database::PostgresInfo) = "postgres"
name(database::DBInfo) = getfield(database, :name)


struct DatabaseSettings{T<:DBInfo}
    main::T #main database
    attached::Vector{<:T} #databases to attach during queries
    # push_period::Union{Int, Nothing} #changed to sample_frequency (not in db settings)
    # checkpoint::Bool
    full_store::Bool #NOTE: do we want to handle this this way?
end

main(db_settings::DatabaseSettings) = getfield(db_settings, :main)
main(::Nothing) = nothing
attached(db_settings::DatabaseSettings) = getfield(db_settings, :attached)
attached(::Nothing) = nothing
type(db_settings::DatabaseSettings) = type(main(db_settings))
type(::Nothing) = nothing


"""
    NoDatabaseError

Type used to for error handling to signal that no database is configured.
"""
struct NoDatabaseError <: Exception
    message::String
    NoDatabaseError() = new("no database is configured!")
end

"""
    NotFoundError

Type used to for error handling to signal that the queried item was not found.
"""
struct NotFoundError <: Exception
    message::String
    NotFoundError() = new("Item was not found in the configured database.")
end

assert_db() = @assert !isnothing(Interactions.DATABASE()) Database.NoDatabaseError()



include("utility.jl")

#include JSON parsing helper functions
include("json.jl")

#include QueryParams types for SQL query generation
include("queryparams.jl")

#include SQL file loader
include("load_sql.jl")

# include sqlite and postgresql specific APIs
include("./sqlite/database_api.jl")
include("./sqlite/sql_queryparams.jl") #NOTE: this ALL needs to be reorganized
# include("./postgres/database_api.jl")

include("./default_barriers.jl")

end #Database