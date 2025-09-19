tempdirpath(db_filepath::String) = rsplit(db_filepath, ".", limit=2)[1] * "/"



function collect_temp(db_info_master::SQLiteInfo, directory_path::String; cleanup_directory::Bool = false, kwargs...)
    contents = readdir(directory_path)
    for item in contents
        item_path = normpath(joinpath(directory_path, item))
        if isfile(item_path)
            db_info_merger = SQLiteInfo("temp", item_path)
            success = false
            while !success
                try
                    merge_temp(db_info_master, db_info_merger; kwargs...)
                    success = true
                catch e
                    if e isa SQLiteException
                        println("An error has been caught in db_collect_temp():")
                        showerror(stdout, e)
                        sleep(rand(0.1:0.1:4.0))
                    else
                        throw(e)
                    end
                end
            end
            println("[$item_path] merged")
            flush(stdout)
        else
            collect_temp(db_info_master, item_path, cleanup_directory=cleanup_directory)
        end
    end
    cleanup_directory && rm(directory_path, recursive=true)
    return nothing
end






function get_incomplete_simulation_uuids(db_info::SQLiteInfo)
    uuids::Vector{String} = query_incomplete_simulations(db_info)[:, :uuid]
    return uuids
end

function has_incomplete_simulations(db_info::SQLiteInfo)
    return !isempty(db_get_incomplete_simulation_uuids(db_info))
end
