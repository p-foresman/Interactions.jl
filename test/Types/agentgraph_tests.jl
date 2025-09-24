using Test
using Interactions


@testset "agentgraph Tests" begin
    @testset "Type Alias Tests" begin
        @test typeof(Interactions.Types.AgentSet{2, Interactions.Types.Agent}(fill(Interactions.Types.Agent(), 2))) == Interactions.Types.StaticArrays.SVector{2, Interactions.Types.Agent}
        @test typeof(Interactions.Types.VertexSet{5}([1, 2, 3, 4, 5])) == Interactions.Types.StaticArrays.SVector{5, Int}
        @test typeof(Interactions.Types.Relationship((1, 2))) == Interactions.GraphsExt.Graphs.SimpleEdge{Int}
        @test typeof(Interactions.Types.RelationshipSet{2}([Interactions.Types.Relationship((1, 2)), Interactions.Types.Relationship((2, 3))])) == Interactions.Types.StaticArrays.SVector{2, Interactions.Types.Relationship}
    end

    @testset "ConnectedComponent Tests" begin

        # g = Interactions.GraphsExt.Graphs.complete_graph(10)


        @test fieldnames(Interactions.Types.ConnectedComponent) == (:vertices, :matches_per_period)
        @test fieldtypes(Interactions.Types.ConnectedComponent) == (Interactions.Types.VertexSet, Int)
        

        @testset "Constructors" begin

        end
        
        @testset "Accessors" begin

        end
    end

    @testset "AgentGraph Tests" begin
        @test fieldnames(Interactions.Types.AgentGraph) == (:graph, :agents, :components, :number_hermits)
        @test fieldtypes(Interactions.Types.AgentGraph) == (Interactions.GraphsExt.Graph, Interactions.Types.AgentSet, Interaction.Types.ComponentSet, Int)
        

        @testset "Constructors" begin

        end
        
        @testset "Accessors" begin

        end
    end
end