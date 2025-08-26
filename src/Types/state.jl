#NOTE: Should I separate the database stuff into an inner type? (model_id, prev_simulation_uuid, rng_state_str)

# mutable struct StateMutables #this increased time
#     period::Int128 #NOTE: should this be added? if so, must make struct mutable and add const before agentgraph and preallocatedarrays
#     complete::Bool
#     timedout::Bool # used to determine whether a periodic push or a full exit is necessary
#     prev_simulation_uuid::Union{String, Nothing} #needs to be updated when pushing to db periodically
#     rng_state_str::Union{String, Nothing} #NOTE: change to Xoshiro down the line? Updated before being pushed to db

#     StateMutables() = new(Int128(0), false, false, nothing, nothing)
# end

mutable struct State{S1, S2, L, A, V, E, C}
    const model::Model{S1, S2, L, A} # {S1, S2}
    const agentgraph::AgentGraph{V, E, C, A}
    const preallocatedarrays::PreAllocatedArrays #NOTE: PreAllocatedArrays currently 2 players only
    const model_id::Union{Int, Nothing}
    const random_seed::Union{Int, Nothing}
    # mutables::StateMutables
    period::Int128 #NOTE: should this be added? if so, must make struct mutable and add const before agentgraph and preallocatedarrays
    complete::Bool
    timedout::Bool # used to determine whether a periodic push or a full exit is necessary
    prev_simulation_uuid::Union{String, Nothing} #needs to be updated when pushing to db periodically
    rng_state_str::Union{String, Nothing} #NOTE: change to Xoshiro down the line? Updated before being pushed to db
end

"""
    BlankState(model::Model, model_id::Union{Int, Nothing}=nothing, random_seed::Union{Int, Nothing}=nothing)

Generates an uninitialized State instance.
"""
function BlankState(model::Model{S1, S2, L, A}; model_id::Union{Int, Nothing}=nothing, random_seed::Union{Int, Nothing}=nothing) where {S1, S2, L, A}
    # agentgraph::AgentGraph = AgentGraph(model)
    agentgraph::AgentGraph = AgentGraph(generate_graph(model), A)
    V = num_vertices(agentgraph)
    E = num_edges(agentgraph)
    C = num_components(agentgraph)
    preallocatedarrays::PreAllocatedArrays = PreAllocatedArrays(game(model))

    # all_user_variables = merge(Interactions.user_variables(parameters(model)), user_variables) #user_variables defined here should go last so that values overwrite defaults if applicable!
    # is_stopping_condition_test = parameters(model).stoppingcondition(model)
    return State{S1, S2, L, A, V, E, C}(model, agentgraph, preallocatedarrays, model_id, random_seed, Int128(0), false, false, nothing, nothing)
end

"""
    State(model::Model; model_id::Union{Int, Nothing}=nothing, random_seed::Union{Int, Nothing}=nothing)

Generates a State instance that gets initialized with a user-supplied starting condition function.
"""
function State(model::Model; kwargs...)
    state = BlankState(model; kwargs...)
    starting_condition_fn_call(state)
    return state
end

"""
    starting_condition_fn_call(state::State)

Call the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' Model field.
"""
starting_condition_fn_call(state::State) = starting_condition_fn(model(state))(state)


"""
    interaction_fn_call(state::State)

Call the user-defined interaction function which correlates to the String stored in the 'starting_condition_fn_str' Model field.
"""
interaction_fn_call(state::State) = interaction_fn(model(state))(state)


"""
    model(state::State)

Get the model from which the state was generated.
"""
model(state::State) = getfield(state, :model)

"""
    period(state::State)

Get the current period of the simulation.
"""
period(state::State) = getfield(state, :period)

"""
    period!(state::State, value::Integer)

Set the period of the simulation to value.
"""
period!(state::State, value::Integer) = setfield!(state, :period, Int128(value))

"""
    increment_period!(state::State)

Increment the period of the simulation.
"""
increment_period!(state::State) = period!(state, period(state) + 1)

"""
    complete!(state::State)

Mark the state as 'completed'
"""
complete!(state::State) = setfield!(state, :complete, true)

"""
    iscomplete(state::State)

Check if the state is 'completed'
"""
iscomplete(state::State) = getfield(state, :complete)


timedout!(state::State) = setfield!(state, :timedout, true)
istimedout(state::State) = getfield(state, :timedout)

# prev_simulation_uuid(state::State) = getfield(state, :prev_simulation_uuid)
prev_simulation_uuid!(state::State, uuid::String) = setfield!(state, :prev_simulation_uuid, uuid)


# AgentGraph
"""
    agentgraph(state::State)

Get the AgentGraph instance in the model.
"""
agentgraph(state::State) = getfield(state, :agentgraph)

num_vertices(state::State) = num_vertices(agentgraph(state))

num_edges(state::State) = num_edges(agentgraph(state))

num_components(state::State) = num_components(agentgraph(state))

"""
    graph(state::State)

Get the graph (Graphs.SimpleGraph{Int}) in the model.
"""
graph(state::State) = graph(agentgraph(state))

"""
    adjacency_matrix_str(state::State)

Get the adjacency matrix in a string for the graph of the given Model
"""
adjacency_matrix_str(state::State) = GraphsExt.adjacency_matrix_str(graph(state))

"""
    agents(state::State)

Get all of the agents in the model.
"""
agents(state::State) = agents(agentgraph(state))

"""
    agents(state::State, agent_number::Integer)

Get the agent indexed by the agent_number in the model.
"""
agents(state::State, agent_number::Integer) = agents(agentgraph(state), agent_number)

"""
    components(state::State)

Get all of the connected componentd that reside in a the model's AgentGraph instance.
Returns a vector of ConnectedComponent objects.
"""
components(state::State) = components(agentgraph(state))

"""
    components(state::State, component_number::Integer)

Get the ConnectedComponent object indexed by component_number in an AgentGraph instance's 'components' field.
"""
components(state::State, component_number::Integer) = components(agentgraph(state), component_number)

# """
#     edges(state::State)

# Get all of the edges/relationships in the model.
# """
# edges(state::State) = edges(agentgraph(state))

# """
#     edges(state::State, edge_number::Integer)

# Get the edge indexed by the edge_number in the model.
# """
# edges(state::State, edge_number::Integer) = edges(agentgraph(state), edge_number)

# """
#     random_edge(state::State)

# Get a random edge/relationship in the model.
# """
# random_edge(state::State) = random_edge(agentgraph(state))

# """
#     component_vertex_sets(state::State)

# Get all of the connected component vertex sets that reside in the model's AgentGraph instance.
# Returns a vector of vectors, each containing the vertices in each separated component.
# """
# component_vertex_sets(state::State) = component_vertex_sets(agentgraph(state))

# """
#     component_vertex_sets(state::State, component_number::Integer)

# Get the connected component vertex set indexed by component_number in the model's AgentGraph instance.
# Returns a vector of Int.
# """
# component_vertex_sets(state::State, component_number::Integer) = component_vertex_sets(agentgraph(state), component_number)

# """
#     component_edge_sets(state::State)

# Get all of the connected component edge sets that reside in the model's AgentGraph instance.
# Returns a vector of vectors, each containing the edges in each separated component.
# """
# component_edge_sets(state::State) = component_edge_sets(agentgraph(state))

# """
#     component_edge_sets(state::State, component_number::Integer)

# Get the connected component edge set indexed by component_number in the model's AgentGraph instance.
# Returns a vector of Graphs.SimpleEdge instances.
# """
# component_edge_sets(state::State, component_number::Integer) = component_edge_sets(agentgraph(state), component_number)

# """
#     component_edge_sets(state::State, component_number::Integer, edge_number::Integer)

# Get the edge indexed by edge_number in the connected component edge set indexed by component_number in the model's AgentGraph instance.
# Returns a Graphs.SimpleEdge instance.
# """
# component_edge_sets(state::State, component_number::Integer, edge_number::Integer) = component_edge_sets(agentgraph(state), component_number, edge_number)

# """
#     random__component_edge(state::State, component_number::Integer)

# Get a random edge/relationship in the component specified by component_number in the model's AgentGraph instance.
# """
# random_component_edge(state::State, component_number::Integer) = rand(component_edge_sets(agentgraph(state), component_number))

"""
    number_hermits(state::State)

Get the number of hermits (vertecies with degree=0) in the model.
"""
number_hermits(state::State) = number_hermits(agentgraph(state))




#PreAllocatedArrays
"""
    preallocatedarrays(state::State)

Get the PreAllocatedArrays instance in the model.
"""
preallocatedarrays(state::State) = getfield(state, :preallocatedarrays)

"""
    players(state::State)

Get the currently cached players in the model.
"""
players(state::State) = players(preallocatedarrays(state))

"""
    players(state::State, player_number::Integer)

Get the player indexed by player_number currently cached in the model.
"""
players(state::State, player_number::Integer) = players(preallocatedarrays(state), player_number)

"""
    player!(state::State, player_number::Integer, agent::Agent)

Set the player indexed by player_number to the Agent instance agent.
"""
player!(state::State, player_number::Integer, agent::Agent) = player!(preallocatedarrays(state), player_number, agent)

"""
    player!(state::State, player_number::Integer, agent_number::Integer)

Set the player indexed by player_number to the Agent instance indexed by agent_number in the AgentGraph instance.
"""
player!(state::State, player_number::Integer, agent_number::Integer) = player!(preallocatedarrays(state), player_number, agents(state, agent_number))

"""
    set_players!(state::State, component::ConnectedComponent)

Choose a random relationship/edge in the specified component and set players to be the agents that the edge connects.
"""
function set_players!(state::State, component::ConnectedComponent)
    v = rand(vertices(component))
    player!(state, 1, v)
    player!(state, 2, rand(GraphsExt.neighbors(graph(state), v)))
    # edge::Graphs.SimpleEdge{Int} = random_edge(component)
    # vertex_list::Vector{Int} = shuffle!([src(edge), dst(edge)]) #NOTE: is the shuffle necessary here?
    # for player_number in 1:2 #NOTE: this will always be 2. Should I just optimize for two player games?
    #     player!(state, player_number, vertex_list[player_number])
    # end
    return nothing
end

function set_players!(state::State)
    v = rand(agentgraph(state).vertices)
    player!(state, 1, v)
    player!(state, 2, rand(neighbors(graph(state), v)))
    # edge::Graphs.SimpleEdge{Int} = random_edge(component)
    # vertex_list::Vector{Int} = shuffle!([src(edge), dst(edge)]) #NOTE: is the shuffle necessary here?
    # for player_number in 1:2 #NOTE: this will always be 2. Should I just optimize for two player games?
    #     player!(state, player_number, vertex_list[player_number])
    # end
    return nothing
end

#temp for complete_graph
# function set_players!(state::State) #NOTE: this could be better
#     v = rand(Graphs.vertices(graph(state)))
#     player!(state, 1, v)
#     player!(state, 2, rand(neighbors(graph(state), v)))
#     return nothing
# end

"""
    opponent_strategy_recollection(state::State)

Get the currently cached recollections of each player (i.e., the quantity of each strategy that resides in players' memories).
"""
opponent_strategy_recollection(state::State) = opponent_strategy_recollection(preallocatedarrays(state))

"""
    opponent_strategy_recollection(state::State, player_number::Integer)

Get the currently cached recollection of the player indexed by player_number.
"""
opponent_strategy_recollection(state::State, player_number::Integer) = opponent_strategy_recollection(preallocatedarrays(state), player_number)

"""
    opponent_strategy_recollection(state::State, player_number::Integer, index::Integer)

Get the currently cached recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection(state::State, player_number::Integer, index::Integer) = opponent_strategy_recollection(preallocatedarrays(state), player_number, index)

"""
    opponent_strategy_recollection!(state::State, player_number::Integer, index::Integer, value::Int)

Set the recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection!(state::State, player_number::Integer, index::Integer, value::Int) = opponent_strategy_recollection!(preallocatedarrays(state), player_number, index, value)

"""
    increment_opponent_strategy_recollection!(state::State, player_number::Integer, index::Integer, value::Int=1)

Increment the recollection of a strategy indexed by index of the player indexed by player_number by value (defaults to an increment of 1).
"""
increment_opponent_strategy_recollection!(state::State, player_number::Integer, index::Integer, value::Int=1) = increment_opponent_strategy_recollection!(preallocatedarrays(state), player_number, index, value)

"""
    opponent_strategy_probabilities(state::State)

Get the currently cached probabilities that each player's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(state::State) = opponent_strategy_probabilities(preallocatedarrays(state))

"""
    opponent_strategy_probabilities(state::State, player_number::Integer)

Get the currently cached probabilities that the player indexed by player_number's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(state::State, player_number::Integer) = opponent_strategy_probabilities(preallocatedarrays(state), player_number)

"""
    opponent_strategy_probabilities(state::State, player_number::Integer, index::Integer)

Get the currently cached probability that the player indexed by player_number's opponent will play the strategy indexed by index.
"""
opponent_strategy_probabilities(state::State, player_number::Integer, index::Integer) = opponent_strategy_probabilities(preallocatedarrays(state), player_number, index)

"""
    expected_utilities(state::State)

Get the cached expected utilities for playing each strategy for both players.
"""
expected_utilities(state::State) = expected_utilities(preallocatedarrays(state))

"""
    expected_utilities(state::State, player_number::Integer)

Get the cached expected utilities for playing each strategy for the player indexed by player_number.
"""
expected_utilities(state::State, player_number::Integer) = expected_utilities(preallocatedarrays(state), player_number)

"""
    expected_utilities(state::State, player_number::Integer, index::Integer)

Get the cached expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities(state::State, player_number::Integer, index::Integer) = expected_utilities(preallocatedarrays(state), player_number, index)

"""
    expected_utilities!(state::State, player_number::Integer, index::Integer, value::AbstractFloat)

Set the expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities!(state::State, player_number::Integer, index::Integer, value::AbstractFloat) = expected_utilities!(preallocatedarrays(state), player_number, index, value)

"""
    increment_expected_utilities!(state::State, player_number::Integer, index::Integer, value::AbstractFloat)

Increment the expected utility for playing the strategy indexed by index for the player indexed by player_number by value.
"""
increment_expected_utilities!(state::State, player_number::Integer, index::Integer, value::AbstractFloat) = increment_expected_utilities!(preallocatedarrays(state), player_number, index, value)

"""
    reset_arrays!(state::State)

Reset the cached arrays in the model's PreAllocatedArrays instance to zeros.
"""
reset_arrays!(state::State) = reset_arrays!(preallocatedarrays(state))




# Parameters
"""
    parameters(state::State)

Get the parameters in the model associated with the state.
"""
parameters(state::State) = parameters(model(state))

"""
    parameters(state::State, param::Symbol)

Get the value of the parameter given.
"""
parameters(state::State, param::Symbol) = parameters(model(state), param)


# Variables
"""
    variables(state::State)

Get the Parameters instance in the model.
"""
variables(state::State) = variables(model(state))

"""
    variables(state::State, variable::Symbol)

Get the value of the parameter given.
"""
variables(state::State, variable::Symbol) = variables(model(state), variable)

variables!(state::State, variable::Symbol, value) = variables!(model(state), variable, value)


# """
#     user_variables(state::State)

# Get the extra user-defined State variables.
# """
# user_variables(state::State) = getfield(state, :user_variables)

# """
#     user_variables(state::State, variable::Symbol)

# Get the value of the specified user-defined variable.
# """
# user_variables(state::State, variable::Symbol) = user_variables(state)[variable]

# """
#     set_user_variable!(state::State, variable::Symbol, value::)

# Get the extra user-defined State variables.
# """
# function set_user_variable!(state::State, variable::Symbol, value::T) where {T}
#     @assert user_variables(state)[variable] isa T "Type of user variable must remain constant!"
#     user_variables(state)[variable] = value
# end


rng_state_str(state::State) = getfield(state, :rng_state_str)
# rng_state(state::State) = JSON3.read(rng_state_str(state), Random.Xoshiro)
rng_state!(state::State) = setfield!(state, :rng_state_str, JSON3.write(copy(Random.default_rng())))
# rng_state_str!(state::State, rng_state_str::String) =  setfield!(state, :rng_state_str, rng_state_str) #NOTE: dont want this method

function restore_rng_state(state::State)
    if !isnothing(rng_state_str(state))
        copy!(Random.default_rng(), JSON3.read(rng_state_str(state), Random.Xoshiro))
    end
    return nothing
end

# """
#     initialize_graph!(model::Model)

# Initialize the AgentGraph instance for the model based on parameters of other model components.
# """
# initialize_graph!(model::Model) = initialize_graph!(graphmodel(model), game(model), parameters(model), startingcondition(model)) #parameter spreading necessary for multiple dispatch

# """
#     initialize_stopping_condition!(state::State, model::Model)

# Initialize the stopping condition values for the model based on parameters of the model's Parameters instance and properties of the AgentGraph instance.
# """
# initialize_stopping_condition!(state::State, model::Model) = initialize_stopping_condition!(stoppingcondition(model), parameters(model), agentgraph(state)) #parameter spreading necessary for multiple dispatch


# """
#     reset_agent_graph!(state::State, model::Model)

# Reset the AgentGraph of the model state.
# """
# reset_agent_graph!(state::State, model::Model) = initialize_agent_data!(agentgraph(state), game(model), parameters(model), startingcondition(model))

# """
#     reset_model!(model::Model)

# Reset the model to its initial state.
# """
# function reset_state!(state::State, model::Model) #NOTE: THIS DOESNT WORK BECAUSE OF IMMUTABLE STRUCT (could work within individual fields)
#     reset_agent_graph!(state, model)
#     initialize_stopping_condition!(state, model)
#     reset_arrays!(state)
#     return nothing
# end

# function regenerate_state(model::Model) #can just call State(model)
#     return State(model)
# end