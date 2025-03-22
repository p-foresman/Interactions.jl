"""
    Model{S1, S2, V, E}

A type which defines the entire model for simulation. Contains Game, Parameters, GraphModel, StartingCondition,
StoppingCondition, AgentGraph, and PreAllocatedArrays.

S1 = row dimension of Game instance
S2 = column dimension of Game instance
V = number of agents/vertices
E = number of relationships/edges
"""
mutable struct Model{S1, S2, L} #, GM <: GraphModel}
    # id::Union{Nothing, Int}
    const game::Game{S1, S2, L}
    const parameters::Parameters
    const graphmodel::GraphModel #NOTE: make this a concrete type for better performance? (tried and didnt help)
    graph::Union{Nothing, GraphsExt.Graph} #pass graph in here to be passed to state. if no graph is passed, it's generated when state is initialized

    function Model(game::Game{S1, S2, L}, params::Parameters, graphmodel::GraphModel) where {S1, S2, L}
        # graph::GraphsExt.Graph = generate_graph(graphmodel, number_agents(params)) #if no graph is passed, it's generated when state is made!
        return new{S1, S2, L}(game, params, graphmodel, nothing)
    end
    function Model(game::Game{S1, S2, L}, params::Parameters, graphmodel::GraphModel, graph::GraphsExt.Graph) where {S1, S2, L}
        return new{S1, S2, L}(game, params, graphmodel, graph) #this constructor allows a graph to be fed in
    end
    function Model(game::Game{S1, S2, L}, params::Parameters, graphmodel::GraphModel, graph_adj_matrix::Matrix) where {S1, S2, L}
        @assert size(graph_adj_matrix)[1] == size(graph_adj_matrix)[2] "adjecency matrix must be equal lengths in both dimensions"
        graph = GraphsExt.Graph(graph_adj_matrix) #this constructor allows an adjacency matrix to be fed in for graph generation
        return new{S1, S2, L}(game, params, graphmodel, graph)
    end
    function Model(game::Game{S1, S2, L}, params::Parameters, graphmodel::GraphModel, graph_adj_matrix_str::String) where {S1, S2, L}
        graph = GraphsExt.Graph(graph_adj_matrix_str) #this constructor allows an adjacency matrix string to be fed in for graph generation
        return new{S1, S2, L}(game, params, graphmodel, graph)
    end
    # function Model(model::Model) #used to generate a new model with the same parameters (newly sampled random graph structure)
    #     return Model(game(model), parameters(model), graphmodel(model), startingcondition(model), stoppingcondition(model), id(model))
    # end
end

function Models(game::Game, params::Parameters, graphmodel::GraphModel; count::Int) #NOTE: dont know what this is used for, can probably delete
    return fill(Model(game, params, graphmodel), count)
end


##########################################
# PreAllocatedArrays Accessors
##########################################

# """
#     id(model::Model)

# Get the id of a Model instance (primarily for distributed computing purposes).
# """
# id(model::Model) = getfield(model, :id)

#Game
"""
    game(model::Model)

Get the Game instance in the model.
"""
game(model::Model) = getfield(model, :game)

"""
    payoff_matrix(game::Model)

Get the payoff matrix for the model.
"""
payoff_matrix(model::Model) = payoff_matrix(game(model))

"""
    strategies(game::Model)

Get the possible strategies that can be played in the model.
"""
strategies(model::Model) = strategies(game(model))

"""
    strategies(game::Model, player_number::Int)

Get the possible strategies that can be played by the given player number in the model.
"""
strategies(model::Model, player_number::Int) = strategies(game(model), player_number)

"""
    random_strategy(game::Model)

Get a random strategy from the possible strategies that can be played in the model.
"""
random_strategy(model::Model, player_number::Int) = random_strategy(game(model), player_number)


# Parameters
"""
    parameters(model::Model)

Get the Parameters instance in the model.
"""
parameters(model::Model) = getfield(model, :parameters)

"""
    number_agents(model::Model)

Get the population size simulation parameter of the model.
"""
number_agents(model::Model) = number_agents(parameters(model)) #NOTE: do this change for all?
# number_agents(model::Model{S1, S2, V, E}) where {S1, S2, V, E} = V #number_agents(parameters(model)) #NOTE: do this change for all?

"""
    memory_length(model::Model)

Get the memory length simulation parameter m of the model.
"""
memory_length(model::Model) = memory_length(parameters(model))

"""
    error_rate(params::Model)

Get the error rate simulation parameter ϵ of the model.
"""
error_rate(model::Model) = error_rate(parameters(model))

# """
#     matches_per_period(params::Model)

# Get the number of matches per period for the model.
# """
# matches_per_period(model::Model) = matches_per_period(parameters(model))

"""
    random_seed(params::Model)

Get the random seed for the model.
"""
random_seed(model::Model) = random_seed(parameters(model))


"""
    starting_condition_fn_str(model::Model)

Get the 'starting_condition_fn_str' Parameters field.
"""
starting_condition_fn_str(model::Model) = starting_condition_fn_str(parameters(model))

"""
    starting_condition_fn(model::Model)

Get the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' Parameters field.
"""
starting_condition_fn(model::Model) = starting_condition_fn(parameters(model))

"""
    starting_condition_fn_call(model::Model, agentgraph::AgentGraph)

Call the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' Parameters field.
"""
starting_condition_fn_call(model::Model, agentgraph::AgentGraph) = starting_condition_fn(model)(model, agentgraph)


"""
    stopping_condition_fn_str(model::Model)

Get the 'stopping_condition_fn_str' Parameters field.
"""
stopping_condition_fn_str(model::Model) = stopping_condition_fn_str(parameters(model))

"""
    stopping_condition_fn(model::Model)

Get the user-defined stopping condition function which correlates to the String stored in the 'stopping_condition_fn' Parameters field.
"""
stopping_condition_fn(model::Model) = stopping_condition_fn(parameters(model))

"""
    get_enclosed_stopping_condition_fn(model::Model)

Call the user-defined stopping condition function which correlates to the String stored in the 'starting_condition_fn_str' Parameters field to get the enclosed function.
"""
get_enclosed_stopping_condition_fn(model::Model) = stopping_condition_fn(model)(model) #NOTE: this closure method can probably be eliminated



# GraphModel
"""
    graphmodel(model::Model)

Get the GraphModel instance in the model.
"""
graphmodel(model::Model) = getfield(model, :graphmodel)

# """
#     graph_type(graphmodel::Model)

# Get the graph type of the model
# """
# graph_type(model::Model) = graph_type(graphmodel(model))
# ###add more


#StartingCondition
# """
#     startingcondition(model::Model)

# Get the StartingCondition instance in the model.
# """
# startingcondition(model::Model) = getfield(model, :startingcondition)


# #StoppingCondition
# """
#     stoppingcondition(model::Model)

# Get the StoppingCondition instance in the model.
# """
# stoppingcondition(model::Model) = getfield(model, :stoppingcondition)

"""
    graph(model::Model)

Get the graph associated with a Model instance.
"""
graph(model::Model) = getfield(model, :graph)

"""
    graph!(model::Model, graph::GraphsExt.Graph)

Set the model's active graph.
"""
graph!(model::Model, graph::GraphsExt.Graph) = setfield!(model, :graph, graph)

"""
   generate_graph(model::Model)
   
Generate a graph from the model.
"""
generate_graph(model::Model) = generate_graph(graphmodel(model), parameters(model))

"""
   generate_graph!(model::Model)
   
Generate a graph from the model and set this graph as the model's active graph
"""
function generate_graph!(model::Model)
    graph::GraphsExt.Graph = generate_graph(graphmodel(model), parameters(model))
    graph!(model, graph)
    return graph
end


#NOTE: model might not have a graph
# """
#     number_hermits(model::Model)

# Get the number of hermits (vertecies with degree=0) in the graph of a Model instance.
# """
# number_hermits(model::Model) = GraphsExt.number_hermits(graph(model))


#Model constructor barriers (used to initialize state components from model)

# function AgentGraph(model::Model)
#     agentgraph::AgentGraph = AgentGraph(graph(model))
#     # initialize_agent_data!(agentgraph, game(model), parameters(model), startingcondition(model))
#     starting_condition_fn_call(model, agentgraph) #get the user-defined starting condition function and use it to initialize the AgentGraph instance
#     return agentgraph
# end

"""
    AgentGraph(model::Model)

Initialize an AgentGraph from a model
"""
function AgentGraph(model::Model)
    if !isnothing(graph(model))
        ag = AgentGraph(graph(model))
    else
        ag = AgentGraph(generate_graph(graphmodel(model), parameters(model)))
    end
    starting_condition_fn_call(model, ag) #get the user-defined starting condition function and use it to initialize the AgentGraph instance
    return ag
end

# """
#     AgentGraph(model::Model, graph::GraphsExt.Graph)

# Initialize an AgentGraph from a model with a pre-provided graph. The model population must equal the number of vertices in the graph provided.
# """
# function AgentGraph(model::Model, graph::GraphsExt.Graph)
#     @assert number_agents(model) == GraphsExt.nv(graph)  "The model population must equal the number of vertices in the graph provided"
#     #NOTE: could also check if graph could have been generated from the specific graph model, or just leave it up to the user
#     agentgraph::AgentGraph = AgentGraph(graph)
#     starting_condition_fn_call(model, agentgraph) #get the user-defined starting condition function and use it to initialize the AgentGraph instance
#     return agentgraph
# end


#NOTE: moved to state
# """
#     adjacency_matrix_str(model::Model)

# Get the adjacency matrix in a string for the graph of the given Model
# """
# adjacency_matrix_str(model::Model) = GraphsExt.adjacency_matrix_str(graph(model))


PreAllocatedArrays(model::Model) = PreAllocatedArrays(game(model))











function Base.show(model::Model)
    println("\n")
    print("Game: ")
    show(game(model))
    print("Graph Model: ")
    show(graphmodel(model))
    print("Sim Params: ")
    show(parameters(model))
    # print("Start: ")
    # show(parameters(model).startingcondition)
    # println()
    # print("Stop: ")
    # show(parameters(model).stoppingcondition)
    # println()
end