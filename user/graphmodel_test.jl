using Interactions

include("startingconditions.jl")
include("stoppingconditions.jl")

# function er(N::Int)
#     return (λ::Real; kwargs...) -> begin
#         @assert λ <= N - 1 "λ must be <= N - 1"
#         num_edges = edge_count(N, edge_density(N, λ))
#         return Graphs.erdos_renyi(N, num_edges; kwargs...)
#     end
# end

function erdos_renyi(parameters::Parameters, λ::Real; kwargs...)
    N = number_agents(parameters)
    num_edges = Interactions.GraphsExt.edge_count(N, Interactions.GraphsExt.edge_density(N, λ))
    g::Interactions.GraphsExt.Graphs.SimpleGraph = Interactions.GraphsExt.Graphs.erdos_renyi(N, num_edges; kwargs..., is_directed=false)
    return g
end

function complete(parameters::Parameters)
    N = number_agents(parameters)
    return Interactions.GraphsExt.complete_graph(N)
end

p = Parameters(10, 10, 0.1, "fractious_starting_condition", "partially_reinforced_equity_stopping_condition", user_variables=UserVariables(:period_count=>0))
const m = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                    p,
                    GraphModel("complete"))

const m4 = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                    p,
                    GraphModel("erdos_renyi", λ=5))




qp_games = Database.Query_games(["Bargaining Game"])
qp_parameters = Database.Query_parameters(10, 10, 0.1, "fractious_starting_condition", "partially_reinforced_equity_stopping_condition")
qp_graphmodels = Database.Query_graphmodels(Database.Query_GraphModel("erdos_renyi"))
qp_models = Database.Query_simulations(qp_games, qp_parameters, qp_graphmodels, sample_size=1)
df = Database.db_query(qp_models, ensure_samples=false)

qp_simulations_1 = Database.Query_simulations(qp_games, qp_parameters_1, qp_graphmodels; sims_kwargs...)
