const sim_params = SimParams(number_agents=30, memory_length=13, memory_init_state=:fractious, error=0.1, tag1=:red, tag2=:blue, tag1_proportion=1.0, random_seed=1234)


const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])
#Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section

# s1 = size(payoff_matrix, 1)
# s2 = size(payoff_matrix, 2)

#create bargaining game type (players will be slotted in)
const game = Game{3, 3}("Bargaining Game", payoff_matrix)

const graph_params = CompleteParams()


const graph = GamesOnNetworks.initGraph(graph_params, game, sim_params)

const agent1 = Agent("agent1", :red, 0, [(:red, Int8(1)), (:red, Int8(2)), (:red, Int8(3)), (:red, Int8(1)), (:red, Int8(2)), (:red, Int8(3)), (:red, Int8(2)), (:red, Int8(2)), (:red, Int8(3)), (:red, Int8(1))])
const agent2 = Agent("agent1", :red, 0, [(:red, Int8(1)), (:red, Int8(1)), (:red, Int8(3)), (:red, Int8(3)), (:red, Int8(2)), (:red, Int8(3)), (:red, Int8(1)), (:red, Int8(1)), (:red, Int8(3)), (:red, Int8(1))])
