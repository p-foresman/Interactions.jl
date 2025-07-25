using Distributed, TOML

const project_dirpath() = dirname(Base.active_project()) #these must be functions so they don't store the paths where Interactions is precompiled
const default_toml_path() = joinpath(@__DIR__, "default_config.toml")
const user_toml_path() = joinpath(project_dirpath(), "Interactions.toml")


# abstract type Database end

# struct Database.PostgresInfo <: Database
#     name::String
#     user::String
#     host::String
#     port::String
#     password::String
# end

# struct Database.SQLiteInfo <: Database
#     name::String
#     filepath::String
# end

# db_type(database::Database.SQLiteInfo) = "sqlite"
# db_type(database::Database.PostgresInfo) = "postgres"



struct Settings
    # data::Dict{String, Any} #Base.ImmutableDict #contains the whole parsed .toml config (dont really need)
    use_seed::Bool
    random_seed::Int
    # use_distributed::Bool
    procs::Int
    timeout::Union{Int, Nothing}
    timeout_exit_code::Int
    database::Union{Database.DatabaseSettings, Nothing} #if nothing, not using database
    # database::Union{Database.DBInfo, Nothing} #if nothing, not using database
    # push_period::Union{Int, Nothing}
    # query::Vector{<:Database.DBInfo} #will be empty if no databse selected
    # checkpoint::Bool
    figure_dirpath::String
    # data_script::Union{Nothing, String}
end

_nosettings() = throw("Interactions.SETTINGS is not congigured!") #this should never really happen

DATABASE(settings::Settings) = getfield(settings, :database)
DATABASE(::Nothing) = _nosettings()
DATABASE() = DATABASE(Interactions.SETTINGS)

USE_DB(settings::Settings) = !isnothing(DATABASE(settings))
USE_DB(::Nothing) = _nosettings()
USE_DB() = USE_DB(Interactions.SETTINGS)

MAIN_DB(settings::Settings) = Database.main(DATABASE(settings))
MAIN_DB(::Nothing) = _nosettings()
MAIN_DB() = MAIN_DB(Interactions.SETTINGS)

ATTACHED_DBS(settings::Settings) = Database.attached(DATABASE(settings))
ATTACHED_DBS(::Nothing) = _nosettings()
ATTACHED_DBS() = ATTACHED_DBS(Interactions.SETTINGS)

DB_TYPE(settings::Settings) = Database.type(DATABASE(settings))
DB_TYPE(::Nothing) = _nosettings()
DB_TYPE() = DB_TYPE(Interactions.SETTINGS)

FIGURE_DIRPATH(settings::Settings) = getfield(settings, :figure_dirpath)
FIGURE_DIRPATH(::Nothing) = _nosettings()
FIGURE_DIRPATH() = FIGURE_DIRPATH(Interactions.SETTINGS)


function Settings(settings::Dict{String, Any})
    @assert haskey(settings, "use_seed") "config file must have a 'use_seed' variable"
    use_seed = settings["use_seed"]
    @assert use_seed isa Bool "'use_seed' value must be a Bool"

    @assert haskey(settings, "random_seed") "config file must have a 'random_seed' variable"
    random_seed = settings["random_seed"]
    @assert random_seed isa Int && random_seed >= 0 "'random_seed' value must be an Int (>= 0)"


    # @assert haskey(settings, "use_distributed") "config file must have a 'use_distributed' variable"
    # use_distributed = settings["use_distributed"]
    # @assert use_distributed isa Bool "'use_distributed' value must be a Bool"

    @assert haskey(settings, "processes") "config file must have a 'processes' variable"
    procs = settings["processes"]
    @assert procs isa Int && procs >= 1 "'processes' value must be a positive Int (>=1)"

    @assert haskey(settings, "timeout") "config file must have a 'timeout' variable"
    timeout = settings["timeout"]
    @assert timeout isa Int && timeout >= 0 "'timeout' value must be a positive Int (>=1) OR 0 (denoting no timeout)"
    if timeout == 0
        timeout = nothing
    end
    
    @assert haskey(settings, "timeout_exit_code") "config file must have a 'timeout_exit_code' positive integer variable"
    timeout_exit_code = settings["timeout_exit_code"]
    @assert timeout_exit_code isa Int && timeout_exit_code >= 0 "'timeout_exit_code' value must be a positive Int (>=1) OR 0 (denoting no exit)"

    @assert haskey(settings, "figure_dirpath") "config file must have a 'figure_dirpath' variable"
    figure_dirpath = settings["figure_dirpath"]
    @assert figure_dirpath isa String "the 'figure_dirpath' variable must be a String (empty string for project root)"
    figure_dirpath = normpath(joinpath(project_dirpath(), figure_dirpath))

    @assert haskey(settings, "databases") "config file must have a [databases] table"
    databases = settings["databases"]
    @assert databases isa Dict "[databases] must be a table (Dict)"
    @assert haskey(databases, "selected") "config file must have a 'selected' database path in the [databases] table using dot notation of the form \"db_type.db_name\" OR an empty string if not using a database"
    selected_db = databases["selected"]
    @assert selected_db isa String "the denoted default database must be a String (can be an empty string if not using a database)"
    
    @assert haskey(databases, "push_period") "config file must have a 'push_period' variable in the [databases] table set to an Integer (can be 0 for no periodic push)"
    push_period = databases["push_period"]
    @assert push_period isa Int "'push_period' must be an Integer (can be 0 for no periodic push)"
    
    #NOTE: should these be under 'databases'? (exit_code probably shouldn't!)
    @assert haskey(databases, "checkpoint") "config file must have a 'checkpoint' boolean variable. This field's value only matters if a database is selected"
    checkpoint = databases["checkpoint"]
    @assert checkpoint isa Bool "'checkpoint' value must be a Bool"

    @assert haskey(databases, "full_store") "config file must have a 'full_store' boolean variable. This field's value only matters if a database is selected"
    full_store = databases["full_store"]
    @assert full_store isa Bool "'full_store' value must be a Bool"

    # @assert haskey(databases, "checkpoint_database") "config file must have a 'checkpoint_database' database path in the [databases] table using dot notation of the form \"db_type.db_name\" OR an empty string to use main selected database"

    # @assert haskey(databases, "data_script") "config file must have a 'data_script' variable in the [databases] table specifying the path to a data loading script to be loaded on database initialization OR an empty string if no data loading is required"
    # data_script = databases["data_script"]
    # @assert data_script isa String "the 'data_script' variable must be a String (can be an empty string if data loading isn't required)"
    # if !isempty(data_script)
    #     data_script = normpath(joinpath(project_dirpath, data_script))
    #     @assert isfile(data_script)
    # else
    #     data_script = nothing
    # end

    #NOTE: change error message
    @assert haskey(databases, "attached") "config file must have an 'attached' variable containing an array of databases to attach to the selected database while performing queries in the [databases] table using dot notation of the form \"db_type.db_name\". If array is empty, the 'selected' database will be queried"
    attached_dbs = databases["attached"]
    @assert attached_dbs isa Vector "'the 'attached' variable must be a Vector"
    @assert all(q->q isa String, attached_dbs) "the 'attached' variable must be an array of Strings using dot notation of the form \"db_type.db_name\" OR an empty array"

    #if selected_db exists, must validate selected database. Otherwise, not using database
    database = nothing #selected database
    # checkpoint = nothing #checkpoint database
    if !isempty(selected_db)
        selected = validate_database(databases, "selected", selected_db)
        attached = Vector{typeof(selected)}() #will ensure that all dbs in query are the same type
        for attached_db in attached_dbs
            # if attach_db != selected_db
            push!(attached, validate_database(databases, "attached", attached_db))
            # end
        end

        database = Database.DatabaseSettings{typeof(selected)}(selected, attached, iszero(push_period) ? nothing : push_period, checkpoint, full_store)
        # if databases["checkpoint"]
        #     checkpoint_db = databases["checkpoint_database"]
        #     if isempty(checkpoint_db)
        #         checkpoint = Checkpoint(database)
        #     else
        #        checkpoint = Checkpoint(validate_database(databases, "checkpoint_database", checkpoint_db))
        #     end
        # end
    end

    return Settings(use_seed, random_seed, procs, timeout, timeout_exit_code, database, figure_dirpath) # settings, 
end

function Settings(toml_path::String)
    @assert last(split(toml_path, ".")) == "toml" "config file be .toml"
    # settings = TOML.parsefile(toml_path)
    return Settings(TOML.parsefile(toml_path))
end

function validate_database(databases::Dict, field::String, db_path::String)
    parsed_db_key_path = split(db_path, ".")
    @assert length(parsed_db_key_path) == 2 "'$field' database path must be of the form \"db_type.db_name\""

    db_type::String, db_name::String = parsed_db_key_path
    @assert db_type == "sqlite" || db_type == "postgres" "'db_type in the '$field' database path (of the form \"db_type.db_name\") must be 'sqlite' or 'postgres'"
    @assert haskey(databases, db_type) "config file does not contain table [databases.$db_type]"
    @assert databases[db_type] isa Dict "[databases.$db_type] must be a table (Dict)"
    @assert haskey(databases[db_type], db_name) "config file does not contain table [databases.$db_type.$db_name]"
    @assert databases[db_type][db_name] isa Dict "[databases.$db_type.$db_name] must be a table (Dict)"

    db_info = databases[db_type][db_name]
    if db_type == "sqlite"
        @assert haskey(db_info, "path") "database config table [database.sqlite.$db_name] must contain 'path' variable"
        @assert db_info["path"] isa String "database config table [database.sqlite.$db_name] 'path' variable must be a String"
        return Database.SQLiteInfo(db_name, normpath(joinpath(project_dirpath(), db_info["path"]))) #NOTE: could use pwd() here to create database in the current directory (more freedom, more potential bugs)
    elseif db_type == "postgres"
        @assert haskey(db_info, "user") "database config table [database.postgres.$db_name] must contain 'user' variable"
        @assert haskey(db_info, "host") "database config table [database.postgres.$db_name] must contain 'host' variable"
        @assert haskey(db_info, "port") "database config table [database.postgres.$db_name] must contain 'port' variable"
        @assert haskey(db_info, "password") "database config table [database.postgres.$db_name] must contain 'password' variable"
        return Database.PostgresInfo(db_name, db_info["user"], db_info["host"], db_info["port"], db_info["password"])
    end
end



"""
    get_default_config(;overwrite::bool=false)

Get the default Interactions.toml config file. CAUTION: setting overwrite=true will replace your current Interactions.toml file.
"""
function get_default_config(;overwrite::Bool=false)
    cp(default_toml_path(), user_toml_path(), force=overwrite)
    chmod(user_toml_path(), 0o777) #make sure the file is writable
    println("default config file added to project directory as 'Interactions.toml'. Use this file to configure package settings.")
end


"""
    Interactions.configure()

Load the Interactions.toml config file to be used in the Interactions package
"""
function configure(toml_path::String="")
    # println(project_dirpath())
    # println(default_toml_path())
    # println(user_toml_path())
    if isempty(toml_path) #if no .toml filepath is provided, try to get the Interactions.toml in the project directory. If this doesn't exist, use the default_config.toml, which will be generated within the project directory as Interactions.toml
        if isfile(user_toml_path())
            #load the user's settings config
            myid() == 1 && println("configuring Interactions using Interactions.toml")
            toml_path = user_toml_path()
        else
            #load the default config which come with the package
            myid() == 1 && println("configuring using the default config")
            toml_path = default_toml_path()
        
            #give the user the default .toml file to customize if desired
            myid() == 1 && get_default_config()
        end
    else
        @assert (splitext(toml_path)[2] == ".toml") "toml_path provided does not have a .toml extension"
        toml_path = abspath(toml_path)
    end

    #create the global SETTINGS variable
    global SETTINGS = Settings(toml_path)


    if myid() == 1
        if USE_DB()
            #initialize the database
            print("initializing databse [$(DB_TYPE()).$(MAIN_DB().name)]... ")
            # out = stdout
            # redirect_stdout(devnull)
            Database.db_init(MAIN_DB()) #;data_script=SETTINGS.data_script) #suppress the stdout stream
            #NOTE: add a "state" database table which stores db info like 'initialized' (if initialized is true, dont need to rerun initialization)
            if MAIN_DB() isa Database.SQLiteInfo
                println("SQLite database file initialized at $(MAIN_DB().filepath)")
            else
                println("PostgreSQL database initialized")
            end

            #NOTE: really should make sure that exist with the right setup, not initialize new ones
            for attached_db in ATTACHED_DBS()
                print("verifying attached databse [$(Database.type(attached_db)).$(attached_db.name)]... ")
                # out = stdout
                # redirect_stdout(devnull)
                Database.db_init(attached_db) #;data_script=SETTINGS.data_script) #suppress the stdout stream
                #NOTE: add a "state" database table which stores db info like 'initialized' (if initialized is true, dont need to rerun initialization)
                if MAIN_DB() isa Database.SQLiteInfo #NOTE: is this necessary?
                    println("SQLite database file verified at $(attached_db)")
                else
                    println("PostgreSQL database verified")
                end
            end

            # if !isnothing(SETTINGS.checkpoint) && SETTINGS.checkpoint.database != SETTINGS.database
            #     print("initializing checkpoint databse [$(db_type(SETTINGS.checkpoint.database)).$(SETTINGS.checkpoint.database.name)]... ")

            #     db_init(SETTINGS.checkpoint.database)

            #     if SETTINGS.checkpoint.database isa Database.SQLiteInfo
            #         println("SQLite database file initialized at $(SETTINGS.checkpoint.database.filepath)")
            #     else
            #         println("PostgreSQL database initialized")
            #     end
            # end
        end

        resetprocs() #resets the process count to 1 for proper reconfigure
        if SETTINGS.procs > 1 #|| SETTINGS.timeout > 0 #if the timeout is active, need to add a process for the timer to run on
            #initialize distributed processes with Interactions available in their individual scopes
            print("initializing $(SETTINGS.procs) distributed processes... ")
            procs = addprocs(SETTINGS.procs, exeflags=`--project=$(Base.active_project())`)
            @everywhere procs begin
                eval(quote
                    # include(joinpath(dirname(@__DIR__), "Interactions.jl")) # this method errors on other local projects since the project environment doesn't contain all of the dependencies (Graphs, Plots, etc)
                    # using .Interactions
                    import Pkg
                    Pkg.activate($$(project_dirpath()); io=devnull) #must activate the local project environment to gain access to the Interactions package
                    using Interactions #will call __init__() on startup for these processes which will configure all processes internally
                end)
            end

            # define registry functions on all worker procs
            if isdefined(Main, :Interactions) #the following won't work on __init__ since Interactions isn't yet defined! However, on subsequent configure() calls, the distributed procs will be updated.
                Registry.update_everywhere(:GraphModels, :_graphmodel_fn_register)
                Registry.update_everywhere(:StartingConditions, :_starting_condition_fn_register)
                Registry.update_everywhere(:StoppingConditions, :_stopping_condition_fn_register)
            end            

        end
        println("$(SETTINGS.procs) $(SETTINGS.procs > 1 ? "processes" : "process") initialized")

        if myid() == 1
            mkpath(SETTINGS.figure_dirpath)
            println("figure directory initialized at $(SETTINGS.figure_dirpath)")
        end

        println("configuration complete")
    end
end