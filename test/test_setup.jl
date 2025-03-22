const sim_params_1 = SimParams(number_agents = 10,
                            memory_length = 10,
                            error = 0.1,
                            tag1 = :red,
                            tag2 = :blue,
                            tag1_proportion = 1.0,
                            random_seed = 1234)

const sim_params_2 = SimParams(number_agents = 30,
                            memory_length = 13,
                            error = 0.1,
                            tag1 = :red,
                            tag2 = :blue,
                            tag1_proportion = 1.0,
                            random_seed = 1234)

const sim_params_3 = SimParams(number_agents = 100,
                            memory_length = 10,
                            error = 0.1,
                            tag1 = :red,
                            tag2 = :blue,
                            tag1_proportion = 1.0,
                            random_seed = 1234)



const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])

const game = Game("Bargaining Game", payoff_matrix)


const graph_params_complete = CompleteParams()
const graph_params_er = ErdosRenyiParams(3.0)
const graph_params_sw = SmallWorldParams(4, 0.6)
const graph_params_sf = ScaleFreeParams(4.0)
const graph_params_sbm = StochasticBlockModelParams(2, 5.0, 0.5)


const starting_condition_fractious = FractiousState(game)
const stopping_condition_equity_psychological = EquityPsychological(game, 2)

model
