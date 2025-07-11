using Test
using Interactions

@testset "Game Tests" begin

    
    a = Interactions.Agent("name")

    @testset "Accessors" begin
        @test displayname(a) == "name"
    end

end
