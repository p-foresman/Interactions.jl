include("sql.jl")

db_init(db_info::PostgresInfo) = execute_init_db(db_info)

db_insert_sim_group(db_info::PostgresInfo, description::String) = execute_insert_sim_group(db_info, description)

function db_insert_game(db_info::PostgresInfo, game::Game)
    game_name = game.name
    game_json_str = JSON3.write(game)
    payoff_matrix_size = JSON3.write(size(game))
    return execute_insert_game(db_info, game_name, game_json_str, payoff_matrix_size)
end

function db_insert_graph(db_info::PostgresInfo, graph_model::GraphModel)
    graph = displayname(graph_model)
    type = String(graph_type(graph_model))
    graph_model_string = JSON3.write(graph_model)
    db_params_dict = Dict{Symbol, Any}(:λ => nothing, :β => nothing, :α => nothing, :blocks => nothing, :p_in => nothing, :p_out => nothing) #allows for parameter-based queries
    
    for param in keys(db_params_dict)
        if param in fieldnames(typeof(graph_model))
            db_params_dict[param] = getfield(graph_model, param)
        end
    end

    return execute_insert_graph(db_info, graph, type, graph_model_string, db_params_dict)
end

function db_insert_sim_params(db_info::PostgresInfo, sim_params::SimParams, use_seed::Bool)
    sim_params_json_str = JSON3.write(sim_params)
    return execute_insert_sim_params(db_info, sim_params, sim_params_json_str, string(use_seed))
end

function db_insert_starting_condition(db_info::PostgresInfo, starting_condition::StartingCondition)
    starting_condition_json_str = JSON3.write(typeof(starting_condition)(starting_condition)) #generates a "raw" starting condition object for the database
    return execute_insert_starting_condition(db_info, starting_condition.name, starting_condition_json_str)
end

function db_insert_stopping_condition(db_info::PostgresInfo, stopping_condition::StoppingCondition)
    stopping_condition_json_str = JSON3.write(typeof(stopping_condition)(stopping_condition)) #generates a "raw" stopping condition object for the database
    return execute_insert_stopping_condition(db_info, stopping_condition.name, stopping_condition_json_str)
end

function db_insert_simulation(db_info::PostgresInfo, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, db_id_tuple::DatabaseIdTuple, agent_graph::AgentGraph, periods_elapsed::Integer, distributed_uuid::Union{String, Nothing} = nothing)
    #prepare simulation to be inserted
    adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(agent_graph.graph)))
    rng_state = copy(Random.default_rng())
    rng_state_json = JSON3.write(rng_state)

    #prepare agents to be inserted
    agents_list = Vector{String}([])
    for agent in agent_graph.agents
        agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
        push!(agents_list, agent_json_str)
    end

    return execute_insert_simulation(db_info, sim_group_id, prev_simulation_uuid, db_id_tuple, adj_matrix_json_str, rng_state_json, periods_elapsed, agents_list)
end



# #NOTE: FIX
# function db_restore_model(db_filepath::String, simulation_id::Integer) #MUST FIX TO USE UUID
#     simulation_df = execute_query_simulations_for_restore(db_filepath, simulation_id)
#     agents_df = execute_query_agents_for_restore(db_filepath, simulation_id)

#     #reproduce SimParams object
#     reproduced_sim_params = JSON3.read(simulation_df[1, :sim_params], SimParams)

#     #reproduce Game object
#     payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
#     payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
#     reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})

#     #reproduced Graph     ###!! dont need to reproduce graph unless the simulation is a pure continuation of 1 long simulation !!###
#     reproduced_graph_model = JSON3.read(simulation_df[1, :graph_model], GraphModel)
#     reproduced_adj_matrix = JSON3.read(simulation_df[1, :graph_adj_matrix], MMatrix{reproduced_sim_params.number_agents, reproduced_sim_params.number_agents, Int})
#     reproduced_graph = SimpleGraph(reproduced_adj_matrix)
#     reproduced_meta_graph = MetaGraph(reproduced_graph) #*** MUST CHANGE TO AGENT GRAPH
#     for vertex in vertices(reproduced_meta_graph)
#         agent = JSON3.read(agents_df[vertex, :agent], Agent)
#         set_prop!(reproduced_meta_graph, vertex, :agent, agent)
#     end

#     #restore RNG to previous state
#     if simulation_df[1, :use_seed] == 1
#         seed_bool = true
#         reproduced_rng_state = JSON3.read(simulation_df[1, :rng_state], Random.Xoshiro)
#         copy!(Random.default_rng(), reproduced_rng_state)
#     else
#         seed_bool = false
#     end
#     return (game=reproduced_game, sim_params=reproduced_sim_params, graph_model=reproduced_graph_model, meta_graph=reproduced_meta_graph, use_seed=seed_bool, periods_elapsed=simulation_df[1, :periods_elapsed], sim_group_id=simulation_df[1, :sim_group_id])
# end