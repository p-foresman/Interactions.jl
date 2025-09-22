using Interactions, Test

@testset "Types Tests" begin
    
    #include sample user files
    include("user/interactions.jl")
    include("user/graphmodels.jl")

    #include tests
    include("games_tests.jl")
    include("agents_test.jl")
    include("interactionmodel_tests.jl")
end