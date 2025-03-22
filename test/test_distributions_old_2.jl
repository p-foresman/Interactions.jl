using HypothesisTests, Distributions, StatsPlots, StatsBase, Graphs

TestType = OneSampleADTest
# samples = 10000
alpha = 2
theta = 1
nodes = 100
scaler = 0.03

dist = Pareto(alpha, theta)
# X = rand(dist, samples)
# test = TestType(X, dist)
# p = pvalue(test)
# hist = histogram(X; bins = 50, normalize = :pdf, label = "pvalue = $(round(p; digits=3))")
# xrange = range(1, maximum(X); length = 100)
# plot!(xrange, pdf.(dist, xrange); color = :black, label = "analytic")
# # axislegend(ax)
# hist


function scale_free(n::Int, α::Int; m_scaler::Float64 = 0.5)
    m_possible = (n * (n-1)) / 2
    m = Int(round(m_scaler * m_possible))
    println(m)
    return static_scale_free(n, m, α)
end

sf_graph = scale_free(nodes, alpha, m_scaler=scaler)
degrees = degree(sf_graph)

plot(degrees)


test = TestType(degrees, dist)
p = pvalue(test)

hist = histogram(degrees; bins = 50, normalize = :pdf, label = "pvalue = $(round(p; digits=3))")
xrange = range(1, maximum(degrees); length = 100)
plot!(xrange, pdf.(dist, xrange); color = :black, label = "analytic")
# axislegend(ax)
hist
# samples = 10000
# pareto_dist = Pareto(1.38, 1)
# X = map(x->round(x), rand(pareto_dist, samples))
# histogram(X)
# plot(sort(X, rev=true))
# plot(pareto_dist, xlims=[0, 10])
# hist_data = countmap(X)
# frequency_dist = sort([frequency / samples for frequency in values(hist_data)], rev=true)
# plot(frequency_dist)
# p = OneSampleADTest(frequency_dist, pareto_dist)
# ks = ApproximateOneSampleKSTest(frequency_dist, pareto_dist)
