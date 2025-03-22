# Attempt to modularize all of the sql queryies using CTEs (Common Table Expressions)

abstract type QueryParams end

# These use a naming convention of Query_tablename so that the tablename is explicit and easily retrievable from the type name

#NOTE: merge these into Generators at some point (its almost a total rewrite)
#NOTE: should each vector automatically sort?

struct Query_games <: QueryParams
    name::Vector{String}
end
Query_games() = Query_games(Vector{String}())
Query_games(name::String, others::String...) = new(Vector{String}([name, others...]))

size(qp::Query_games) = length(qp.name) #NOTE: rename to qsize?


struct Query_parameters <: QueryParams
    number_agents::Vector{Int}
    memory_length::Vector{Int}
    error::Vector{Float64}
    starting_condition::Vector{String}
    stopping_condition::Vector{String}
end

function Query_parameters(number_agents::Union{Integer, Vector{<:Integer}}=Vector{Int}(),
    memory_length::Union{Integer, Vector{<:Integer}}=Vector{Int}(),
    error::Union{Real, Vector{<:Real}}=Vector{Float64}(),
    starting_condition::Union{String, Vector{String}}=Vector{String}(),
    stopping_condition::Union{String, Vector{String}}=Vector{String}()
)
    if starting_condition isa String starting_condition = Vector{String}([starting_condition]) end
    if stopping_condition isa String stopping_condition = Vector{String}([stopping_condition]) end

    return Query_parameters([number_agents...], [memory_length...], [error...], starting_condition, stopping_condition)
end

size(qp::Query_parameters) = Interactions.volume(Interactions.fieldvals(qp)...)


# abstract type Query_GraphModel <: QueryParams end
# struct Query_graphmodels_CompleteModel <: Query_GraphModel end
# size(::Query_graphmodels_CompleteModel) = 1

# struct Query_graphmodels_ErdosRenyiModel <: Query_GraphModel
#     λ::Vector{Float64}
# end
# Query_graphmodels_ErdosRenyiModel() = Query_graphmodels_ErdosRenyiModel(Vector{Float64}())
# Query_graphmodels_ErdosRenyiModel(λ::Real, others::Real...) = Query_graphmodels_ErdosRenyiModel(Vector{Float64}([λ, others...]))

# struct Query_graphmodels_SmallWorldModel <: Query_GraphModel
#     λ::Vector{Float64}
#     β::Vector{Float64}

#     function Query_graphmodels_SmallWorldModel(λ::Union{Real, Vector{<:Real}}=Vector{Float64}(),
#                                                β::Union{Real, Vector{<:Real}}=Vector{Float64}())

#         return new([λ...], [β...])
#     end
# end

# struct Query_graphmodels_ScaleFreeModel <: Query_GraphModel
#     λ::Vector{Float64}
#     α::Vector{Float64}

#     function Query_graphmodels_ScaleFreeModel(λ::Union{Real, Vector{<:Real}}=Vector{Float64}(),
#                                               α::Union{Real, Vector{<:Real}}=Vector{Float64}())

#         return new([λ...], [α...])
#     end
# end

# struct Query_graphmodels_StochasticBlockModel <: Query_GraphModel
#     λ::Vector{Float64}
#     blocks::Vector{Int}
#     p_in::Vector{Float64}
#     p_out::Vector{Float64}

#     function Query_graphmodels_StochasticBlockModel(λ::Union{Real, Vector{<:Real}}=Vector{Float64}(),
#                                                     blocks::Union{Integer, Vector{<:Integer}}=Vector{Int}(),
#                                                     p_in::Union{Real, Vector{<:Real}}=Vector{Float64}(),
#                                                     p_out::Union{Real, Vector{<:Real}}=Vector{Float64}())

#         return new([λ...], [blocks...], [p_in...], [p_out...])
#     end
# end


# type(::T) where {T<:Query_GraphModel} = split(string(T), "_")[3]
# size(qp::Query_GraphModel) = Interactions.volume(Interactions.fieldvals(qp)...)


struct Query_GraphModel <: QueryParams
    name::String
    params::NamedTuple

    function Query_GraphModel(name::String; params...)
        params = NamedTuple(params)
        @assert all(i -> isa(i, Real) || isa(i, Vector{<:Real}), values(params)) "All params must Union{Real, Vector{<:Real}}"
        k = keys(params)
        v = map(x->isa(x, Vector) ? x : [x], collect(params))
        return new(name, (; zip(k , v)...)) #zip back into NamedTuple (where all values are now Vector{<:Real})
    end
end

name(qp::Query_GraphModel) = getfield(qp, :name)
params(qp::Query_GraphModel) = getfield(qp, :params)
size(qp::Query_GraphModel) = Interactions.volume(filter(x->(x isa Vector), collect(getfield(qp, :params)))...)
table(qp::Query_GraphModel) = "graphmodels"

struct Query_graphmodels <: QueryParams
    graphmodels::Vector{<:Query_GraphModel}
end
Query_graphmodels(graphmodel::Query_GraphModel, others::Query_GraphModel...) = Query_graphmodels(Vector([graphmodel, others...]))

size(qp::Query_graphmodels) = sum([size(gm) for gm in qp.graphmodels])


# function size(qp::Query_graphmodels)
#     sz = 0
#     for gm in qp.graphmodels
#         sz += size(gm)
#     end
#     return
# end


# struct Query_graphmodels <: QueryParams #NOTE: need an extra specifier for CompleteModel!
#     λ::Vector{Float64} #this OR this AND others
#     β::Vector{Float64}
#     α::Vector{Float64}
#     blocks::Vector{Int}
#     p_in::Vector{Float64}
#     p_out::Vector{Float64}
# end
# function Query_graphmodels(λ::Vector{<:Real}=[],
#     β::Vector{<:Real}=[],
#     α::Vector{<:Real}=[],
#     blocks::Vector{<:Integer}=[],
#     p_in::Vector{<:Real}=[],
#     p_out::Vector{<:Real}=[]
# ) 
#     Query_graphmodels(λ, β, α, blocks, p_in, p_out)
# end

struct Query_models <: QueryParams
    games::Query_games
    parameters::Query_parameters
    graphmodels::Query_graphmodels
end

size(qp::Query_models) = *(size(qp.games), size(qp.parameters), size(qp.graphmodels))
graphmodels(qp::Query_models) = qp.graphmodels.graphmodels #need twice for actual list of graphmodels

struct Query_simulations <: QueryParams #NOTE: this might be overly complicated
    model::Query_models
    complete::Union{Bool, Nothing}
    sample_size::Int

    function Query_simulations(games::Query_games, parameters::Query_parameters, graphmodels::Query_graphmodels; complete::Union{Bool, Nothing}=nothing, sample_size::Integer=0)
        @assert sample_size >= 0 "sample_size must positive (0 for all samples)"
        return new(Query_models(games, parameters, graphmodels), complete, sample_size)
    end
    function Query_simulations(qp_models::Query_models; complete::Union{Bool, Nothing}=nothing, sample_size::Integer=0)
        @assert sample_size >= 0 "sample_size must positive (0 for all samples)"
        return new(qp_models, complete, sample_size)
    end
end

size(qp::Query_simulations) = size(qp.model) #NOTE: should probably just put this in

table(::T) where {T<:QueryParams} = split(string(T), "_")[2]

sample_size(qp::Query_simulations) = getfield(qp, :sample_size)
#need the following for plotting (getting values for different sweep parameters)
number_agents(qp::Query_simulations) = qp.model.parameters.number_agents
memory_length(qp::Query_simulations) = qp.model.parameters.memory_length
error(qp::Query_simulations) = qp.model.parameters.error
graphmodels(qp::Query_simulations) = graphmodels(qp.model)
# function λ(qp::Query_simulations) #this is probably not good, but required for plotting (for now)
#     @assert all(gm -> sort(gm.λ) == graphmodels(qp)[1].λ, graphmodels(qp)) "cannot use this function unless all λ vectors in the query contain the same values"
#     return graphmodels(qp)[1].λ
# end


# function size(qp::QueryParams) #generic size() works for all but Query_graphmodels
#     sz = 1
#     for field in fieldnames(typeof(qp))
#         val = getfield(qp, field)
#         if val isa QueryParams
#             sz *= size(val)
#         elseif val isa Vector #Vector must be second due to Query_graphmodels
#             sz *= length(val)
#         end
#     end
#     return sz
# end


# function sql(qp::Query_models)
#     "WITH CTE_games AS ($(sql(qp.game))), CTE_parameters AS ($(sql(qp.parameters))), CTE_graphmodels AS ($(sql(qp.graphmodel))) SELECT *, model_id FROM CTE_games, CTE_parameters, CTE_graphmodels INNER JOIN models"
# end



function _ensure_samples(df::DataFrame, qp::Query_simulations)
    #check to ensure all samples are present
    model_counts_df = combine(groupby(df, [:number_agents,
                                          :memory_length,
                                          :error,
                                          :starting_condition,
                                          :stopping_condition,
                                          :graphmodel_type,
                                          :λ,
                                          :β,
                                          :α,
                                          :blocks,
                                          :p_in,
                                          :p_out]), nrow=>:count)

    insufficient_samples_models = filter(:count => count -> count < qp.sample_size, model_counts_df)
    !isempty(insufficient_samples_models) && throw(ErrorException("Insufficient samples for the following:\n" * string(insufficient_samples_models)))

    #if a model has 0 samples, it won't show up in dataframe (it wasn't simulated)
    if nrow(model_counts_df) < Database.size(qp)
        throw(ErrorException("At least one model selected has no simulations"))
    end
    return nothing
end