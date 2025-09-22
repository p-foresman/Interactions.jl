using Test
using Interactions

@testset "InteractionModel Tests" begin
    @testset "GraphModel Tests" begin
        @test fieldnames(Interactions.Types.GraphModel) == (:fn_var, :params, :param_types, :kwargs)
        @test fieldtypes(Interactions.Types.GraphModel) == (Symbol, NamedTuple, Tuple, Dict{Symbol, Any})
        
        complete_gm = GraphModel(:complete)
        erdos_renyi_gm = GraphModel(:erdos_renyi, λ=5)
        erdos_renyi_gm_directed = GraphModel(:erdos_renyi, λ=5, kwargs=Dict(:is_directed=>true))

        @testset "Constructors" begin
            @test complete_gm isa GraphModel
            @test erdos_renyi_gm isa GraphModel
            @test erdos_renyi_gm_directed isa GraphModel
            @test_throws Interactions.Registry.NotDefinedError GraphModel(:not_defined)
            @test_throws ErrorException("arguments provided must be in the order of the function parameters") GraphModel(:test_errors, two=2, one=1)
            @test_throws DomainError GraphModel(:test_errors, one=1, two=2)

        end
        
        @testset "Accessors" begin
            @test Interactions.Types.graphmodel_fn_var(complete_gm) == :complete
            @test Interactions.Types.graphmodel_fn_name(complete_gm) == "complete"
            @test Interactions.Types.graphmodel_fn(complete_gm) == Interactions.Registry.GraphModels.complete
            @test Interactions.Types.parameters(erdos_renyi_gm) == (λ=5,)
            @test Interactions.Types.args(erdos_renyi_gm) == (5,)
            @test Interactions.Types.kwargs(erdos_renyi_gm_directed) == Dict(:is_directed=>true)
        end
    end
end