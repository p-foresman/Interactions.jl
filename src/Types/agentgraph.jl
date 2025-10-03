const AgentSet{N, A} = SVector{N, A} where {N, A<:AbstractAgent} #NOTE: these probably shouldnt be static vectors (not good with large arrays) TEST SPEED DIFFERENCE
const VertexSet{V} = SVector{V, Int}
const Relationship = Graphs.SimpleEdge{Int}
const RelationshipSet{E} = SVector{E, Relationship}

#NOTE: STATIC ARRAYS SHOULDNT BE MORE THAN 100 ELEMENTS!



const Graph = Graphs.SimpleGraph{Int} #NOTE: probably want to get rid of this

# """
#     Graph(matrix_str::String)

# Create a Graphs.SimpleGraph{Int} from a matrix string.
# """
# SimpleGraph{Int}(matrix_str::String) = Graph(eval(Meta.parse(matrix_str))) # can call Graph(matrix_str::String) and this will be called ()

# adjacency_matrix_str(graph::Graph) = string(Matrix(adjacency_matrix(graph)))
function number_hermits(graph::Graph)
    number_hermits = 0
    for vertex in Graphs.vertices(graph) #could make graph-type specific multiple dispatch so this only needs to happen for ER and SBM (otherwise num_hermits=0)
        if iszero(Graphs.degree(graph, vertex))
            number_hermits += 1
        end
    end
    return number_hermits
end

function connected_component_vertices(g::Graphs.AbstractGraph{T}) where {T}
    return filter(component -> length(component) > 1, Graphs.connected_components(g))
end

# function connected_component_sets(g::Graphs.AbstractGraph{T}) where {T}
#     component_vertex_sets = connected_component_vertices(g)
#     # component_edges = fill([], length(components))
#     component_count = length(component_vertex_sets)
#     component_edge_sets::Vector{Vector{Graphs.SimpleEdge{Int}}} = []
#     for vertex_set in component_vertex_sets
#         edge_set::Vector{Graphs.SimpleEdge{Int}} = []
#         for edge in Graphs.edges(g)
#             if edge.src in vertex_set && edge.dst in vertex_set
#                 push!(edge_set, edge)
#             end
#         end
#         push!(component_edge_sets, edge_set)
#     end
#     return component_vertex_sets, component_edge_sets, component_count
# end

# function connected_component_edges(g::Graphs.AbstractGraph{T}) where {T}
#     return connected_component_sets(g)[2]
# end

"""
    Interactions.AgentGraph{N, E, C} <: Graphs.AbstractGraph{Int}

A type extending the Graphs.jl SimpleGraph functionality by adding agents to each vertex.
This is a simpler alternative to MetaGraphs.jl for the purposes of this package.

N = number of vertices,
E = number of edges,
C = number of connected components,
A = agent type
"""
struct ConnectedComponent{V, E}
    vertices::VertexSet{V}
    # edges::RelationshipSet{E} #can delete for now to save allocations
    matches_per_period::Int

    function ConnectedComponent(vertices::Vector{Int}, edges::Vector{Relationship})
        V = length(vertices)
        E = length(edges)
        d = E / ((V * (V-1)) / 2) # num edges / num possible edges
        matches_per_period = Int(ceil(d * V / 2)) #ceil to ensure at least one match (unless d=0, in which case nothing would happen regardless) #NOTE: fraction of N choose 2
        return new{V, E}(VertexSet{V}(vertices), matches_per_period) # matches = (periods * d * N) / 2
    end
end

const ComponentSet{C} = SVector{C, ConnectedComponent}
const EmptyComponentSet = ComponentSet{0}

vertices(component::ConnectedComponent) = getfield(component, :vertices)
num_vertices(::ConnectedComponent{V, E}) where {V, E} = V
# edges(component::ConnectedComponent) = getfield(component, :edges)
num_edges(::ConnectedComponent{V, E}) where {V, E} = E
# random_edge(component::ConnectedComponent) = rand(edges(component))
matches_per_period(component::ConnectedComponent) = getfield(component, :matches_per_period)


struct AgentGraph{N, E, C, A} <: Graphs.AbstractGraph{Int}
    # graphmodel::GraphModel #NOTE: should add this here and make the constructor more robust!
    graph::Graph #NOTE: this is already stored in Model, do we need to store it here? probably should still
    agents::AgentSet{N, A}
    components::ComponentSet{C} #NOTE: different ConnectedComponents will have different V and E static params, meaning that getting a specific component from this set wont be type stable. Doesn't account for a huge change in practice with one component, but could find a way to fix or optimize by not using a component set if there is only one component
    number_hermits::Int
    # vertices::VertexSet{N}
    # matches_per_period::Int

    
    function AgentGraph(graph::Graph, AgentType::Type{<:AbstractAgent})
        N = Graphs.nv(graph)
        E = Graphs.ne(graph)
        agents::AgentSet{N, AgentType} = [AgentType(id=agent_number, is_hermit=iszero(Graphs.degree(graph, agent_number))) for agent_number in 1:N]
        # for vertex in 1:N #could make graph-type specific multiple dispatch so this only needs to happen for ER and SBM (otherwise num_hermits=0)
        #     if iszero(Graphs.degree(graph, vertex))
        #         ishermit!(agents[vertex], true)
        #     end
        # end
        # vertex_sets, edge_sets, C = connected_component_sets(graph)
        vertex_sets = filter(component -> length(component) > 1, Graphs.connected_components(graph)) #don't want to store hermits in components since they don't interact
        components = []
        for component_number in 1:C
            # push!(components, ConnectedComponent(vertex_sets[component_number], edge_sets[component_number]))
            push!(components, ConnectedComponent(vertex_sets[component_number], edge_sets[component_number]))
        end

        return new{N, E, C, AgentType}(graph, agents, ComponentSet{C}(components), number_hermits(graph))#, VertexSet{N}(Graphs.vertices(graph)), matches_per_period)
    end
    function AgentGraph(graph::Graph, agents::AgentSet{N, A}) where {N, A}
        @assert N == Graphs.nv(graph) "graph vertex count must equal the number of agents supplied"
        E = Graphs.ne(graph)
        # vertex_sets, edge_sets, C = connected_component_sets(graph)
        vertex_sets = filter(component -> length(component) > 1, Graphs.connected_components(graph)) #don't want to store hermits in components since they don't interact
        components = []
        for component_number in 1:C
            push!(components, ConnectedComponent(vertex_sets[component_number], edge_sets[component_number]))
        end

        return new{N, E, C, A}(graph, agents, ComponentSet{C}(components), number_hermits(graph))#, VertexSet{N}(Graphs.vertices(graph)), matches_per_period)
    end
end

##########################################
# AgentGraph Accessors
##########################################


num_vertices(::AgentGraph{N, E, C}) where {N, E, C} = N

num_edges(::AgentGraph{N, E, C}) where {N, E, C} = E

num_components(::AgentGraph{N, E, C}) where {N, E, C} = C

"""
    graph(agentgraph::AgentGraph)

Get the graph (Graphs.SimpleGraph{Int}) defined in an AgentGraph instance.
"""
graph(agentgraph::AgentGraph) = getfield(agentgraph, :graph)

"""
    agents(agentgraph::AgentGraph)

Get all of the agents in an AgentGraph instance.
"""
agents(agentgraph::AgentGraph) = getfield(agentgraph, :agents)

"""
    agents(agentgraph::AgentGraph, agent_number::Integer)

Get the agent indexed by the agent_number in an AgentGraph instance.
"""
agents(agentgraph::AgentGraph, agent_number::Integer) = getindex(agents(agentgraph), agent_number)

agent_type(::AgentGraph{N, E, C, A}) where {N, E, C, A} = A

# """
#     edges(agentgraph::AgentGraph)

# Get all of the edges/relationships in an AgentGraph instance.
# """
# edges(agentgraph::AgentGraph) = getfield(agentgraph, :edges)

# """
#     edges(agentgraph::AgentGraph, edge_number::Integer)

# Get the edge indexed by the edge_number in an AgentGraph instance.
# """
# edges(agentgraph::AgentGraph, edge_number::Integer) = getindex(edges(agentgraph), edge_number)

# """
#     random_edge(agentgraph::AgentGraph)

# Get a random edge/relationship in an AgentGraph instance.
# """
# random_edge(agentgraph::AgentGraph) = rand(edges(agentgraph))


num_vertices(::VertexSet{V}) where {V} = V

"""
    components(agentgraph::AgentGraph)

Get all of the connected componentd that reside in an AgentGraph instance.
Returns a vector of ConnectedComponent objects.
"""
components(agentgraph::AgentGraph) = getfield(agentgraph, :components)

"""
    components(agentgraph::AgentGraph, component_number::Integer)

Get the ConnectedComponent object indexed by component_number in an AgentGraph instance's 'components' field.
"""
components(agentgraph::AgentGraph, component_number::Integer) = getindex(components(agentgraph), component_number)


# num_edges(::RelationshipSet{E}) where {E} = E


"""
    number_hermits(agentgraph::AgentGraph)

Get the number of hermits (vertecies with degree=0) in an AgentGraph instance.
"""
number_hermits(agentgraph::AgentGraph) = getfield(agentgraph, :number_hermits)#number_hermits(graph(agentgraph))