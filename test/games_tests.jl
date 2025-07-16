using Test
using Interactions, Random

@testset "Game Tests" begin
    @test fieldnames(Interactions.Types.Game) == (:name, :payoff_matrix)
    @test fieldtypes(Interactions.Types.Game) == (String, Interactions.PayoffMatrix)

    pm = [(0, 0) (0, 0) (70, 30);
          (0, 0) (50, 50) (50, 30);
          (30, 70) (30, 50) (30, 30)]
    static_pm = Interactions.PayoffMatrix{3, 3, 9}(pm)

    @testset "Constructors" begin
        @test Game{3, 3, 9}("name", static_pm) isa Game{3, 3, 9}
        @test Game("name", static_pm) isa Game{3, 3, 9}
        @test Game{3, 3, 9}("name", pm) isa Game{3, 3, 9}
        @test Game("name", pm) isa Game{3, 3, 9}
        #@test Game("name") #for zero-sum. NOTE: fix
    end
    
    g = Game("name", pm)

    @testset "Accessors" begin
        @test displayname(g) == "name"
        @test payoff_matrix(g) == static_pm
        @test size(g) == (3, 3)
        @test strategies(g) == (Base.OneTo(3), Base.OneTo(3))
        @test strategies(g, 1) == Base.OneTo(3) #NOTE: change payoff matrix so this is properly tested
        Random.seed!(1)
        @test random_strategy(g, 1) == 1
        @test random_strategy(g, 2) == 2

    end

end
