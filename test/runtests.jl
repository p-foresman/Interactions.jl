ENV["TEST_INTERACTIONS"] = true
using Interactions, Test

@testset "Interactions.jl Tests" begin
    include("games_tests.jl")
    include("agents_test.jl")
end