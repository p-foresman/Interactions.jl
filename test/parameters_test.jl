using Test
using Interactions

@testset "Parameters Tests" begin
    # @test fieldnames(Interactions.Types.Parameters) == (:number_agents, :memory_length, :error, :starting_condition_fn, :stopping_condition_fn_name, :user_variables)
    # @test fieldtypes(Interactions.Types.Parameters) == (Int, Bool, Interactions.Types.PerceptSequence, Interactions.Types.Choice, Interactions.Types.Choice)
    
    # A1 = Interactions.Types.Agent(1, false, [1, 2, 3], 1, 2)
    # A2 = Interactions.Types.Agent(id=2, is_hermit=true)

    # @testset "Constructors" begin
    #     @test A1 isa Interactions.Types.Agent
    #     @test A2 isa Interactions.Types.Agent
    # end
    
    # @testset "Accessors" begin
    #     @test Interactions.Types.id(A1) == 1
    #     @test Interactions.Types.id(A2) == 2
    #     @test displayname(A1) == "1"
    #     @test displayname(A2) == "2"
    #     Interactions.Types.ishermit!(A1, true)
    #     @test Interactions.Types.ishermit(A1) == true
    #     Interactions.Types.ishermit!(A2, false)
    #     @test Interactions.Types.ishermit(A2) == false
    #     @test Interactions.Types.memory(A1) == [1, 2, 3]
    #     @test Interactions.Types.memory(A2) == []
    #     Interactions.Types.rational_choice!(A1, 3)
    #     @test Interactions.Types.rational_choice(A1) == 3
    #     @test Interactions.Types.rational_choice(A2) == 0
    #     Interactions.Types.choice!(A1, 1)
    #     @test Interactions.Types.choice(A1) == 1
    #     @test Interactions.Types.choice(A2) == 0
    # end
end
