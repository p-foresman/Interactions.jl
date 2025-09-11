const Parameters = Dict{Symbol, Float64} #NamedTuple #NOTE: should i just remove these? Probably makes things more confusing for user
const Variables = Dict{Symbol, Float64}
const Arrays = Dict{Symbol, SVector{2, Vector{Float64}}} #rename to PreAllocatedArrays?

"""
    Model{S1, S2, V, E}

A type which defines the entire model for simulation. Contains Game, Parameters, GraphModel, StartingCondition,
StoppingCondition, AgentGraph, and PreAllocatedArrays.

S1 = row dimension of Game instance
S2 = column dimension of Game instance
V = number of agents/vertices
E = number of relationships/edges
"""
struct Model{S1, S2, L, A<:AbstractAgent} #, GM <: GraphModel}
    # id::Union{Nothing, Int}
    agent_type::Type{A}
    population_size::Int
    # population::Tuple{Type{A}, Int} # (agent_type, population_size) --- sticking with one agent type for now, in the future could store a vector of population tuples which describe the population makeup
    # population::Dict{DataType, Int} #NOTE: could do this for heterogeneous population!
    game::Game{S1, S2, L}
    graphmodel::GraphModel #NOTE: make this a concrete type for better performance? (tried and didnt help)
    starting_condition_fn_name::String
    stopping_condition_fn_name::String
    parameters::Parameters #the parameters used in the model (immutable dictionary - these parameters cannot be changed during the course of a simulation)
    variables::Variables #the variables used in the model (these variables can be altered during the course of a simulation)
    arrays::Arrays
    #graph::Union{Nothing, GraphsExt.Graph} #pass graph in here to be passed to state. if no graph is passed, it's generated when state is initialized

    # function Model(population::Tuple{Type{A}, Int}, game::Game{S1, S2, L}, graphmodel::GraphModel, starting_condition_fn_name::String, stopping_condition_fn_name::String; parameters::Parameters=Parameters(), variables::Variables=Variables()) where {A<:AbstractAgent, S1, S2}
    #     @assert isdefined(Registry.StartingConditions, Symbol(starting_condition_fn_name)) "'starting_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @startingcondition macro before function to register it"
    #     @assert isdefined(Registry.StoppingConditions, Symbol(stopping_condition_fn_name)) "'stopping_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @stoppingcondition macro before function to register it"
    #     return new{S1, S2, A}(population, game, graphmodel, starting_condition_fn_name, stopping_condition_fn_name, parameters, variables)
    # end
    function Model(agent_type::Type{A}, population_size::Integer, game::Game{S1, S2, L}, graphmodel::GraphModel, starting_condition_fn_name::String, stopping_condition_fn_name::String; parameters::Parameters=Parameters(), variables::Variables=Variables(), arrays::Arrays=Arrays()) where {A<:AbstractAgent, S1, S2, L}
        @assert isdefined(Registry.StartingConditions, Symbol(starting_condition_fn_name)) "'starting_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @startingcondition macro before function to register it"
        @assert isdefined(Registry.StoppingConditions, Symbol(stopping_condition_fn_name)) "'stopping_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @stoppingcondition macro before function to register it"
        # population::Tuple{Type{A}, Int} = (agent_type, Int(population_size))
        return new{S1, S2, L, A}(agent_type, population_size, game, graphmodel, starting_condition_fn_name, stopping_condition_fn_name, parameters, variables, arrays)
    end
    # function Model(game::Game{S1, S2, L}, params::Parameters, graphmodel::GraphModel, graph::GraphsExt.Graph) where {S1, S2, L}
    #     return new{S1, S2, L}(game, params, graphmodel, graph) #this constructor allows a graph to be fed in
    # end
    # function Model(game::Game{S1, S2, L}, params::Parameters, graphmodel::GraphModel, graph_adj_matrix::Matrix) where {S1, S2, L}
    #     @assert size(graph_adj_matrix)[1] == size(graph_adj_matrix)[2] "adjecency matrix must be equal lengths in both dimensions"
    #     graph = GraphsExt.Graph(graph_adj_matrix) #this constructor allows an adjacency matrix to be fed in for graph generation
    #     return new{S1, S2, L}(game, params, graphmodel, graph)
    # end
    # function Model(game::Game{S1, S2, L}, params::Parameters, graphmodel::GraphModel, graph_adj_matrix_str::String) where {S1, S2, L}
    #     graph = GraphsExt.Graph(graph_adj_matrix_str) #this constructor allows an adjacency matrix string to be fed in for graph generation
    #     return new{S1, S2, L}(game, params, graphmodel, graph)
    # end
end

# function Models(game::Game, params::Parameters, graphmodel::GraphModel; count::Int) #NOTE: dont know what this is used for, can probably delete
#     return fill(Model(game, params, graphmodel), count)
# end


##########################################
# Model Accessors
##########################################

# """
#     agent_type(model::Model)

# Get the agent type (<:AbstractAgent) used in the model.
# """
# agent_type(model::Model) = get_field(model, :agent_type)

# """
#     population(model::Model)

# Get the population description used in the model.
# """
# population(model::Model) = getfield(model, :population)

"""
    agent_type(model::Model)

Get the agent type (<:AbstractAgent) used in the model.
"""
agent_type(model::Model) = getfield(model, :agent_type)

"""
    population_size(model::Model)

Get the population size used in the model.
"""
population_size(model::Model) = getfield(model, :population_size)


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


"""
    interaction_fn_name(model::Model)

Get the 'interaction_fn_name' Game field.
"""
interaction_fn_name(model::Model) = interaction_fn_name(game(model))

"""
    interaction_fn(model::Model)

Get the user-defined interaction function which correlates to the String stored in the 'interaction_fn_name' Game field.
"""
interaction_fn(model::Model) = interaction_fn(game(model))


# GraphModel
"""
    graphmodel(model::Model)

Get the GraphModel instance in the model.
"""
graphmodel(model::Model) = getfield(model, :graphmodel)


# """
#    generate_graph(model::Model)
   
# Generate a graph from the model.
# """
# generate_graph(model::Model) = generate_graph(graphmodel(model), parameters(model))

"""
   generate_graph(model::Model)
   
Generate a graph from the model.
"""
function generate_graph(model::Model)::GraphsExt.Graphs.SimpleGraph
    graph::GraphsExt.Graphs.SimpleGraph = fn(graphmodel(model))(model, args(graphmodel(model))...; kwargs(graphmodel(model))...)
    if GraphsExt.ne(graph) == 0 #NOTE: we aren't considering graphs with no edges (obviously). Does it even make sense to consider graphs with more than one component?
        return generate_graph(model)
    end
    return graph
end

# """
#     AgentGraph(model::Model)

# Initialize an AgentGraph from a model
# """
# function AgentGraph(model::Model)
#     ag = AgentGraph(generate_graph(model), agent_type(model))
#     # starting_condition_fn_call(model, ag) #get the user-defined starting condition function and use it to initialize the AgentGraph instance
#     return ag
# end




"""
    starting_condition_fn_name(model::Model)

Get the 'starting_condition_fn_name' field.
"""
starting_condition_fn_name(model::Model) = getfield(model, :starting_condition_fn_name)

"""
    starting_condition_fn(model::Model)

Get the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_name' field.
"""
starting_condition_fn(model::Model) = getfield(Registry.StartingConditions, Symbol(starting_condition_fn_name(model)))

# """ # moved to State
#     starting_condition_fn_call(model::Model, agentgraph::AgentGraph)

# Call the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' Parameters field.
# """
# starting_condition_fn_call(model::Model, agentgraph::AgentGraph) = starting_condition_fn(model)(model, agentgraph)


"""
    stopping_condition_fn_name(model::Model)

Get the 'stopping_condition_fn_name' field.
"""
stopping_condition_fn_name(model::Model) = getfield(model, :stopping_condition_fn_name)

"""
    stopping_condition_fn(model::Model)

Get the user-defined stopping condition function which correlates to the String stored in the 'stopping_condition_fn' field.
"""
stopping_condition_fn(model::Model) = getfield(Registry.StoppingConditions, Symbol(stopping_condition_fn_name(model)))

"""
    get_enclosed_stopping_condition_fn(model::Model)

Call the user-defined stopping condition function which correlates to the String stored in the 'starting_condition_fn_str' field to get the enclosed function.
"""
get_enclosed_stopping_condition_fn(model::Model) = stopping_condition_fn(model)(model) #NOTE: this closure method can probably be eliminated



# ================
# Model Parameters
# ================

"""
    parameters(model::Model)

Get the Parameters instance in the model.
"""
parameters(model::Model) = getfield(model, :parameters)

"""
    parameters(model::Model, key::Symbol)

Get the value of the parameter given.
"""
parameters(model::Model, key::Symbol) = getindex(parameters(model), key)



# =================
# Initial Variables
# =================

# note: for the model, only getters are implemented

"""
    variables(model::Model)

Get the Parameters instance in the model.
"""
variables(model::Model) = getfield(model, :variables)

"""
    variables(model::Model, name::Symbol)

Get the value of the parameter given.
"""
variables(model::Model, key::Symbol) = getindex(variables(model), key)


# ============================
# Initial Pre Allocated Arrays
# ============================

# note: for the model, only getters are implemented

"""
    arrays(model::Model)

Get the pre-allocated arrays in the model.
"""
arrays(model::Model) = getfield(model, :arrays)

"""
    arrays(model::Model, key::Symbol)

Get the pre-allocated array with the associated key.
"""
arrays(model::Model, key::Symbol) = getindex(arrays(model), key)



function Base.show(model::Model) #NOTE: FIX
    println("\n")
    print("Game: ")
    show(game(model))
    print("Graph Model: ")
    show(graphmodel(model))
    print("Parameters: ")
    show(parameters(model))
    # print("Start: ")
    # show(parameters(model).startingcondition)
    # println()
    # print("Stop: ")
    # show(parameters(model).stoppingcondition)
    # println()
end

###########################################


# """
#     starting_condition_fn_str(model::Model)

# Get the 'starting_condition_fn_str' Parameters field.
# """
# starting_condition_fn_str(model::Model) = starting_condition_fn_str(parameters(model))

# """
#     starting_condition_fn(model::Model)

# Get the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' Parameters field.
# """
# starting_condition_fn(model::Model) = starting_condition_fn(parameters(model))

# """
#     starting_condition_fn_call(model::Model, agentgraph::AgentGraph)

# Call the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' Parameters field.
# """
# starting_condition_fn_call(model::Model, agentgraph::AgentGraph) = starting_condition_fn(model)(model, agentgraph)


# """
#     stopping_condition_fn_str(model::Model)

# Get the 'stopping_condition_fn_str' Parameters field.
# """
# stopping_condition_fn_str(model::Model) = stopping_condition_fn_str(parameters(model))

# """
#     stopping_condition_fn(model::Model)

# Get the user-defined stopping condition function which correlates to the String stored in the 'stopping_condition_fn' Parameters field.
# """
# stopping_condition_fn(model::Model) = stopping_condition_fn(parameters(model))

# """
#     get_enclosed_stopping_condition_fn(model::Model)

# Call the user-defined stopping condition function which correlates to the String stored in the 'starting_condition_fn_str' Parameters field to get the enclosed function.
# """
# get_enclosed_stopping_condition_fn(model::Model) = stopping_condition_fn(model)(model) #NOTE: this closure method can probably be eliminated


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

# """
#     graph(model::Model)

# Get the graph associated with a Model instance.
# """
# graph(model::Model) = getfield(model, :graph)

# """
#     graph!(model::Model, graph::GraphsExt.Graph)

# Set the model's active graph.
# """
# graph!(model::Model, graph::GraphsExt.Graph) = setfield!(model, :graph, graph)



# """
#    generate_graph!(model::Model)
   
# Generate a graph from the model and set this graph as the model's active graph
# """
# function generate_graph!(model::Model)
#     graph::GraphsExt.Graph = generate_graph(graphmodel(model), parameters(model))
#     graph!(model, graph)
#     return graph
# end


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


# PreAllocatedArrays(model::Model) = PreAllocatedArrays(game(model))


