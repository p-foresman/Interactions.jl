using Interactions
using BenchmarkTools, TimerOutputs
include("startingconditions.jl")
include("stoppingconditions.jl")
include("graphmodels.jl")
include("games.jl")


const to = TimerOutput()

game = Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)], "play_game!")
const m2 = Model(Interactions.Types.Agent, 10, game, :erdos_renyi, :fractious_starting_condition, :partially_reinforced_equity_stopping_condition;
                parameters=Parameters(:memory_length=>10, :error_rate=>0.1, :λ=>5),
                variables=Variables(:period_count=>0),
                arrays=Arrays(:opponent_strategy_recollection=>zeros.(Float32, [3, 3]),
                              :opponent_strategy_probabilities=>zeros.(Float32, [3, 3]),
                              :expected_utilities=>zeros.(Float32, [3, 3]))
                )
const s = State(m2)
@btime simulate(m)
simulate(m2; samples=1)


const m4 = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                    p,
                    GraphModel("erdos_renyi"; λ=5))


generator = Interactions.Generators.GraphModelGenerator("erdos_renyi"; λ=[5, 6])
Interactions.Generators.generate_model(generator, 1)

modelgenerator = Interactions.Generators.ModelGenerator(game, [10, 20], [11, 12], [0.1, 0.05], ("fractious_starting_condition", Dict{Symbol, Any}()), ("partially_reinforced_equity_stopping_condition", Dict{Symbol, Any}()), generator)
Interactions.Generators.generate_model(modelgenerator, 1)
# qp_games = Database.Query_games(["Bargaining Game"])
# qp_parameters = Database.Query_parameters(10, 10, 0.1, "fractious_starting_condition", "partially_reinforced_equity_stopping_condition")
# qp_graphmodels = Database.Query_graphmodels(Database.Query_GraphModel("erdos_renyi"))
# qp_models = Database.Query_simulations(qp_games, qp_parameters, qp_graphmodels, sample_size=1)
# df = Database.db_query(qp_models, ensure_samples=false)

# qp_simulations_1 = Database.Query_simulations(qp_games, qp_parameters_1, qp_graphmodels; sims_kwargs...)

mg = ModelGenerator(Interactions.Types.Agent,
                                            [10, 20, 30],
                                            game,
                                            :erdos_renyi,
                                            :fractious_starting_condition,
                                            :partially_reinforced_equity_stopping_condition,
                                            Dict(:memory_length=>[10, 20], :error_rate=>[0.1, 0.09], :λ=>[5, 10]);
                                            variables=Variables(:period_count=>0),
                                            arrays=Arrays(:opponent_strategy_recollection=>zeros.(Float32, [3, 3]),
                                                        :opponent_strategy_probabilities=>zeros.(Float32, [3, 3]),
                                                        :expected_utilities=>zeros.(Float32, [3, 3]))
                                            )

generate_model(mg, 15)