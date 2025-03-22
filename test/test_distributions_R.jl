# use RCall.jl to call the poweRlaws package
using RCall, Graphs, StatsPlots



alpha = 2
# theta = 1
nodes = 1000
scaler = 0.02

m_possible = (nodes * (nodes-1)) / 2
println((nodes^1.5)/m_possible)

function scale_free(n::Int, α::Int) #; m_scaler::Float64 = 0.5)
    m_possible = (n * (n-1)) / 2
    m_scaler = 0.5*exp(-0.006*n)+0.03
    m = Int(round(m_scaler * m_possible))
    println("$m out of $m_possible possible")
    # return static_scale_free(n, m, α)
    return static_scale_free(n, m, α)
end

sf_graph = scale_free(nodes, alpha)
degrees = degree(sf_graph)

println(degrees)

@rput degrees

R"""
library("poweRlaw")
degree_dist_pl = displ$new(degrees)
min_est = estimate_xmin(degree_dist_pl)
degree_dist_pl$setXmin(min_est)
bs_p = bootstrap_p(degree_dist_pl)
p = bs_p$p
"""

@rget degree_dist_pl
@rget p

println(degree_dist_pl)
println(p)

hist = histogram(degrees; bins = 50, normalize = :pdf, label = "pvalue = $(round(p; digits=3))")