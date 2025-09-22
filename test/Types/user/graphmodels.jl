@graphmodel function complete(model::Model)::Interactions.GraphsExt.Graphs.SimpleGraph
    N = population_size(model)
    # g::Interact
    return Interactions.GraphsExt.complete_graph(N)
end

@graphmodel function erdos_renyi(model::Model, λ::Real; kwargs...)
    N = population_size(model)
    num_edges = Interactions.GraphsExt.edge_count(N, Interactions.GraphsExt.edge_density(N, λ))
    g::Interactions.GraphsExt.Graphs.SimpleGraph = Interactions.GraphsExt.Graphs.erdos_renyi(N, num_edges; kwargs..., is_directed=false)
    return g
end

@graphmodel function test_errors(model::Model, one::Real, two::Real; kwargs...)
    N = population_size(model)
    return "not a SimpleGraph"
end