using Test, Interactions, Graphs


@testset "agentgraph Tests" begin
    @testset "Type Alias Tests" begin
        @test typeof(Interactions.Types.AgentSet{2, Interactions.Types.Agent}(fill(Interactions.Types.Agent(), 2))) == Interactions.Types.StaticArrays.SVector{2, Interactions.Types.Agent}
        @test typeof(Interactions.Types.VertexSet{5}([1, 2, 3, 4, 5])) == Interactions.Types.StaticArrays.SVector{5, Int}
        @test typeof(Interactions.Types.Relationship((1, 2))) == Graphs.SimpleEdge{Int}
        @test typeof(Interactions.Types.RelationshipSet{2}([Interactions.Types.Relationship((1, 2)), Interactions.Types.Relationship((2, 3))])) == Interactions.Types.StaticArrays.SVector{2, Interactions.Types.Relationship}
    end

    @testset "Helper Function Tests" begin
        #this graph has two connected components (vertices 1/2, and vertices 3/4) and one hermit (vertex 5)
        test_graph = SimpleGraph([1 1 0 0 0;
                                1 1 0 0 0;
                                0 0 1 1 0;
                                0 0 1 1 0;
                                0 0 0 0 0;])
        @test Interactions.Types.number_hermits(hermit_graph) == 1
        @test Interactions.Types.connected_component_vertices(component_graph) == [[1, 2], [3, 4]]
        @test Interactions.Types.
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