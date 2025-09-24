possible_edge_count(N::Int) = Int((N * (N-1)) / 2)
edge_density(N::Integer, λ::Real) = λ / (N - 1)
edge_count(N::Integer, d::Float64) = Int(round(d * possible_edge_count(N)))
mean_degree(N::Int, d::Float64) = Int(round((N - 1) * d))



function erdos_renyi_rg(N::Integer, λ::Real; kwargs...)
    @assert λ <= N - 1 "λ must be <= N - 1"
    num_edges = edge_count(N, edge_density(N, λ))
    return erdos_renyi(N, num_edges; kwargs...) #we can use d or num_edges here (num_edges will be exact while d will slightly change)
end
# NOTE: edge probability == density for ER, so normal erdos_renyi(n, p) function is already in terms of density

"""
    small_world_rg(N::Integer, λ::Real, β::Real; kwargs...)

Constructor that uses the Graphs.watts_strogatz() method where λ = κ.
"""
function small_world_rg(N::Integer, λ::Real, β::Real; kwargs...)
    @assert λ <= N - 1 "λ must be <= N - 1"
    @assert λ >= 1.5 "λ must be >= 1.5 due to the watts_strogatz graph generator algorithm"
    if λ == N - 1
        return complete_graph(N)
    else
        return watts_strogatz(N, Int(round(λ)), β; kwargs...)
    end
end


function scale_free_rg(N::Integer, λ::Real, α::Real; kwargs...)
    @assert λ <= N - 1 "λ must be <= N - 1"
    num_edges = edge_count(N, edge_density(N, λ))
    return static_scale_free(N, num_edges, α; kwargs...)
end


#NOTE: want to take in overall density as well to remain consistent with others (d). The other things fed are probabilities and inform the SBM
function stochastic_block_model_rg(block_sizes::Vector{<:Integer}, λ::Real, in_block_probs::Vector{<:Real}, out_block_prob::Real)
    @assert λ <= sum(block_sizes) - 1 "λ must be <= N - 1, where N = sum(block_sizes)"
    affinity_matrix = Graphs.SimpleGraphs.sbmaffinity(in_block_probs, out_block_prob, block_sizes)
    N = sum(block_sizes)
    num_edges = edge_count(N, edge_density(N, λ))
    return Graphs.SimpleGraph(N, num_edges, Graphs.StochasticBlockModel(block_sizes, affinity_matrix))
end


function plot_degree_distribution(g)
    hist = degree_histogram(g)
    total_vertices = nv(g)
    normalized_hist = Dict()
    for (degree, num_vertices) in hist
    normalized_hist[degree] = num_vertices/total_vertices
    # append!(x, degree)
    # append!(y, num_vertices/total_vertices)
    end
    return plot(normalized_hist)
end
    
function fit_degree_dist(D, g::SimpleGraph{Int})
    sample_points = degree(g)
    return fit(D, sample_points)
end

function plot_fitted_degree_dist(D, g::SimpleGraph{Int})
    fit = fit_degree_dist(D, g)
    nv = Graphs.nv(g)
    return plot(D, x_lims=[0, nv])
end