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



# """
# Notes:
# SF approaches ER as power law degree (α) tends to infinity (higher α => less nodes with high degree. Therefor, more evenly distributed)
#     -keep α small for sufficiently different degree distribution
#     -choose α values 2, 3, 4, and 10 (10 to show that ER structure is approached)
# ER and SF are p<0.05 at N=50 and p<0.01 at N=60
# SW approaches an ER graph as rewiring probability (β) goes to 1.0 (at 0.0, the graph is regular)
#     -keep β small for a sufficiently different degree distribution
#     -choose β values 0.0, 0.05, 0.1, 0.9 (0.9 to show that ER structure is approached)
#     -for β=0.05, p<0.05 at N=50, for β=0.1, p<0.5 at

#   ER: λ = 1, 2, 3, 4, 5 => 

# All random graphs approach complete graph as density goes to 1.0
#     -choose d values 0.2, 0.4, 0.6, 0.8 to show full range (could eliminate 0.8)


# Steps:
#   1. Show that the AEY model is replicated with N, m, and e sweeps (get matching data)
#   2. Show issue with AEY stopping condition, propose new stopping condition, and show the same results
#   3. Now, we can drop the AEY stopping condition moving forward, since we argue that the new one is useful and results in less artifacts
#   4. Introduce graphs and show that they are sufficiently different from one another with given threshold at certain N (and certain edge density)
#   5. Now, we can drop the sweeps of N moving forward because we've found a sufficient population to compare at, and we're studying the effects of STRUCTURE and NOISE
#       -choose N=100 or something
#   6. We can also drop sweeps of m for the same reason (although these sweeps could be interesting to see, we need to limit our study to structure and noise)
#       -choose m=10
#   7. We do want to sweep the error term to study the interplay of structure and noise
#       -choose e = 0.05, 0.1, 0.15, 0.2, 0.25 (or maybe just 0.05, 0.1, 0.2)
#   8. Edge density plays a crucial factor in the graphs' structures, so we want to sweep edge density
#       -choose d = 0.2, 0.4, 0.6, 0.8 (random graphs will approach complete graph as d->1.0)
#   9. For Erdos-Renyi, we have erdos_renyi(N, d) where d is swept through
#   10. For Small-World, we have small_world(N, d, β) where d and β are swept through
#       -β is the rewiring probability. As β -> 1.0, SW approximates ER (β=0.0 is a regular lattice) 
#       -So, keep β small to keep SW structure sufficiently different from ER
#       -choose β = 0.0, 0.05, 0.1 (do we want to include 0.9 to show that SW approaches ER)
#   11. For Scale-Free, we have scale_free(N, d, α) where d and α are swept through
#       -α is the expected power law degree distribution exponent. As α -> infinity, SF approximates ER
#       -So, keep α small to keep SF structure sufficiently different from ER
#       -choose α = 2, 3, 4 (do we want to include 10 to show that SF approaches ER)
#   13. For Stochastic Block Model, we have stochastic_block_model(block_sizes, d, in_block_prob, out_block_prob) where d, in_block_prob, and out_block_prob are swept through
#       -as in_block_prob and out_block_prob get approach each other (==), SBM approximates ER
#       -So, keep out_block_prob very small while sweeping through larger values of in_block_prob in order to best represent SBM structure
#       -choose 2 equally sized blocks (if N=100, two blocks of size 50)
#       -choose out_block_prob = 0.01 (this may even be too high?) and in_block_prob = 1.0, 0.75, 0.5, 0.25
#   12. For random graphs, this is a total of...
#       -1 starting condition
#       -1 stopping condition
#       -1 population size
#       -1 memory length
#       -5 error rates
#       -4 densities
#           X1 for ER
#           X3 for SF
#           X3 for SF
#           X4 for SBM
#       = 220 simulations (20 samples each)
#
#
#   SCRATCH THAT: MEAN DEGREE (EXPECTED DEGREE) IS WHAT WILL PRESERVE STRUCTURE AS N INCREASES, NOT EDGE DENSITY!! ****
#   Dont bother with random graphs with densities which fall below the giant component threshold.
#   The characteristic social structures for different graph types have certainly not crystalized at this point.
#   (we WANT a giant component)
#
#
# NOTE: new stopping condition breaks down for high error (1-e) term will be small, so small portion of agents need to transition
# """