const SQL = String
const BLOB = Vector{Int8} #type alias for SQL Binary Large Objects

const SQL_CACHE = Dict{String, String}() #cache to store SQL statements to reduce file loading overhead

"""
    load_sql_file(db_type::String, file::String)

Loads and caches the content of an SQL file.
The file is read from disk on the first call and cached for subsequent calls.
"""
function load_sql_file(file::String) #NOTE: could make this more efficient
    filepath = joinpath(@__DIR__, file)
    @assert isfile(filepath) "The filepath given does not correspond to an existing file."
    @assert splitext(filepath)[2] == ".sql" "The filepath given does not correspond to a .sql file."

    # Check if the SQL statement is already in the cache. If not, read it and store it.
    return get!(SQL_CACHE, filepath, read(filepath, String))
end