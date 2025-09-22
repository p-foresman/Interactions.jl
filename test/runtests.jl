ENV["TEST_INTERACTIONS"] = true
using Interactions, Test

@testset "Interactions.jl Tests" begin
    include("Types/runtests.jl")
end