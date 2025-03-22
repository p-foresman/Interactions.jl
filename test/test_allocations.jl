using Distributed
addprocs(4)

@everywhere using GamesOnNetworks

const payoff_matrix = [(0, 0) (0, 0) (70, 30);
                        (0, 0) (50, 50) (50, 30);
                        (30, 70) (30, 50) (30, 30)]

const game_list = [Game{3, 3}("Bargaining Game", payoff_matrix)]

game1 = Game{3, 3}("Bargaining Game", payoff_matrix)

sim_params = SimParams(100, 10, 0.1, random_seed=1234)

graph_params = CompleteParams()

starting = FractiousState()

stopping = PeriodCutoff(1000)

m = SimModel(game1, sim_params, graph_params, starting, stopping)

function test_model(model::SimModel)
    simulate(model, use_seed=true)
    reset_model!(model)
end

simulate_distributed(m, "test.sqlite", run_count=4)