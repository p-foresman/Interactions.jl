using HypothesisTests, Distributions, StatsPlots, StatsBase, Graphs
import Graphs: stochastic_block_model, erdos_renyi #import to extend
include("../src/graphs.jl")

TestType = ApproximateTwoSampleKSTest

# N = 70
# d = 0.
# # λ = mean_degree(N, d)
# λ = 10
# println("λ = $λ")


power_law_degree = 2
rewiring_prob = 0.01

# internal_p = 1.0
# external_p = 0.05

populations = [100, 500, 1000]
densities = [0.9, 0.8, 0.7, 0.6]
lambdas = [10]
runs = 10000
er_sw_p_values = fill(0.0, (length(populations), length(lambdas)))
er_sf_p_values = fill(0.0, (length(populations), length(lambdas)))
sw_sf_p_values = fill(0.0, (length(populations), length(lambdas)))

# complete_degrees = degree(complete_graph(N))

for i in eachindex(populations)
    N = populations[i]
    for j in eachindex(lambdas)
        λ = lambdas[j]
        # λ = mean_degree(N, densities[j])
        er_sw = []
        er_sf = [] 
        sw_sf = []
        for _ in 1:runs
            er_degrees = degree(erdos_renyi_rg(N, λ))
            sf_degrees = degree(scale_free_rg(N, λ, power_law_degree))
            sw_degrees = degree(small_world_rg(N, λ, rewiring_prob))
            push!(er_sw, pvalue(TestType(er_degrees, sw_degrees)))
            push!(er_sf, pvalue(TestType(er_degrees, sf_degrees)))
            push!(sw_sf, pvalue(TestType(sw_degrees, sf_degrees)))
        end
        er_sw_p_values[i, j] = mean(er_sw)
        er_sf_p_values[i, j] = mean(er_sf)
        sw_sf_p_values[i, j] = mean(sw_sf)
    end
end

println("ER/SW:")
display(er_sw_p_values)
println("ER/SF:")
display(er_sf_p_values)
println("SW/SF:")
display(sw_sf_p_values)

er_graph = erdos_renyi_rg(1000, 10)
er_degrees = degree(er_graph)
# println("er: ", ne(er_graph))
histogram(er_degrees; bins = 20, normalize = :pdf, label = "ER", fillalpha=0.4)

# sf_graph = scale_free_rg(N, λ, power_law_degree)
# sf_degrees = degree(sf_graph)
# println("sf: ", ne(sf_graph))


# sw_graph = small_world_rg(N, λ, rewiring_prob)
# sw_degrees = degree(sw_graph)
# println("sw: ", ne(sw_graph))

# sbm_graph = stochastic_block_model_rg(Int.([N/2, N/2]), λ, [internal_p, internal_p], external_p)
# sbm_degrees = degree(sbm_graph)
# println("sbm: ", ne(sbm_graph))

# test_c_er = TestType(complete_degrees, er_degrees)
# test_er_sf = TestType(er_degrees, sf_degrees)
# test_er_sw = TestType(er_degrees, sw_degrees)
# test_sf_sw = TestType(sf_degrees, sw_degrees)
# p_c_er = pvalue(test_c_er)
# p_er_sf = pvalue(test_er_sf)
# p_er_sw = pvalue(test_er_sw)
# p_sf_sw = pvalue(test_sf_sw)
# println("p-value C and ER: ", round(p_c_er; digits=3))
# println("p-value ER and SF: ", round(p_er_sf; digits=3))
# println("p-value ER and SW: ", round(p_er_sw; digits=3))
# println("p-value SF and SW: ", round(p_sf_sw; digits=3))

# test_er_sbm = TestType(er_degrees, sbm_degrees)
# p_er_sbm = pvalue(test_er_sbm)
# println("p-value ER and SBM: ", round(p_er_sbm; digits=3))



# hist = histogram([er_degrees sf_degrees sw_degrees sbm_degrees]; bins = 20, normalize = :pdf, label = ["ER = $(round(p_er_sf; digits=3))" "SF = $(round(p_er_sw; digits=3))" "SW = $(round(p_sf_sw; digits=3))" "SBM = $(round(p_er_sbm; digits=3))"], fillalpha=0.4)
# hist2 = histogram(sf_degrees; bins = 20, normalize = :pdf, label = "SF", fillalpha=0.4)
# hist3 = histogram([er_degrees sf_degrees]; bins = 20, normalize = :pdf, label = ["ER = $(round(p_er_sf; digits=3))" "SF"], fillalpha=0.4)

# xrange = range(0, maximum(er_degrees); length = 100)
# histogram(er_degrees; bins = 50, normalize = :pdf)
# histogram!(xrange, er_degrees; color = :black, label = "analytic")
# axislegend(ax)
# hist