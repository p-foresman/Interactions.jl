abstract type GraphModelGenerator <: Generator end


#NOTE: could somehow generate these out of the actual graphmodels (they have pretty much the same fields, theres got to be a way)
struct CompleteModelGenerator <: GraphModelGenerator
    size::Int

    CompleteModelGenerator() = new(1)
end

struct ErdosRenyiModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    size::Int

    ErdosRenyiModelGenerator(λ::Vector{<:Real}) = new(λ, length(λ)) #NOTE: not yet using λ in these, so size is just 1 here
end

struct SmallWorldModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    β::Vector{Float64}
    size::Int

    SmallWorldModelGenerator(λ::Vector{<:Real}, β::Vector{Float64}) = new(λ, β, Interactions.volume(λ, β))
end

struct ScaleFreeModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    α::Vector{Float64}
    size::Int

    ScaleFreeModelGenerator(λ::Vector{<:Real}, α::Vector{Float64}) = new(λ, α, Interactions.volume(λ, α))
end

struct StochasticBlockModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    blocks::Vector{Int}
    p_in::Vector{Float64}
    p_out::Vector{Float64}
    size::Int

    StochasticBlockModelGenerator(λ::Vector{<:Real}, blocks::Vector{Int}, p_in::Vector{Float64}, p_out::Vector{Float64}) = new(λ, blocks, p_in, p_out, Interactions.volume(λ, blocks, p_in, p_out))
end

# Base.size(graphmodel_generator::GraphModelGenerator) = getfield(graphmodel_generator, :size)

get_params(vec::Vector...; index::Integer) = first(Iterators.drop(Iterators.product(vec...), index - 1))

generate_model(::CompleteModelGenerator, index::Integer) = index == 1 ? CompleteModel() : throw("index must be 1") #NOTE: this seems like a sketchy way to do this, but along with the iterate() below, should never error
generate_model(graphmodel_generator::ErdosRenyiModelGenerator, index::Integer) = ErdosRenyiModel(graphmodel_generator.λ[index])
generate_model(graphmodel_generator::SmallWorldModelGenerator, index::Integer) = SmallWorldModel(get_params(graphmodel_generator.λ, graphmodel_generator.β; index=index)...)
generate_model(graphmodel_generator::ScaleFreeModelGenerator, index::Integer) = ScaleFreeModel(get_params(graphmodel_generator.λ, graphmodel_generator.α; index=index)...)
generate_model(graphmodel_generator::StochasticBlockModelGenerator, index::Integer) = StochasticBlockModel(get_params(graphmodel_generator.λ, graphmodel_generator.blocks, graphmodel_generator.p_in, graphmodel_generator.p_out; index=index)...)

# function Base.iterate(graphmodel_generator::GraphModelGenerator, state=1)
#     if state > graphmodel_generator.size
#         return nothing
#     else
#         return (generate_model(graphmodel_generator, state), state + 1)
#     end    
# end