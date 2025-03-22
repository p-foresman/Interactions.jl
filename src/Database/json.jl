#NOTE: is this file necessary?

parse_simulation_data(data_json::String) = JSON3.read(data_json, Dict{String, Any})
