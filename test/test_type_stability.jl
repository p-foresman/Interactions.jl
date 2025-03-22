using GamesOnNetworks


function fractious_starting_condition(model::SimModel, agentgraph::GamesOnNetworks.AgentGraph)
    for (vertex, agent) in enumerate(agents(agentgraph))
        #set memory initialization
        if vertex % 2 == 0
            recollection = strategies(game(model), 1)[1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = strategies(game(model), 1)[3]
        end
        # empty!(memory(agent))
        # rational_choice!(agent, Choice(0))
        # choice!(agent, Choice(0))
        for _ in 1:memory_length(simparams(model))
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function equity_psychological(model::SimModel) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    sufficient_equity = (1 - error_rate(model)) * memory_length(model)
    sufficient_transitioned = number_agents(model) - number_hermits(model)
    
    return (state::GamesOnNetworks.State) -> begin
        number_transitioned = 0
        for agent in agents(state)
            if !ishermit(agent)
                if count_strategy(memory(agent), 2) >= sufficient_equity
                    number_transitioned += 1
                end
            end
        end 
        return number_transitioned >= sufficient_transitioned
    end
end

function equity_behavioral(model::SimModel) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    sufficient_transitioned = (1 - error_rate(model)) * (number_agents(model) - number_hermits(model))
    period_cutoff = memory_length(model)

    return (state::GamesOnNetworks.State) -> begin
        number_transitioned = 0
        for agent in agents(state)
            if !ishermit(agent)
                if GamesOnNetworks.rational_choice(agent) == 2 #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
                    number_transitioned += 1
                end
            end
        end 

        if number_transitioned >= sufficient_transitioned
            state.custom_variables[:period_count] += 1
            return state.custom_variables[:period_count] >= period_cutoff
        else
            state.custom_variables[:period_count] = 0

            return false
        end
    end
end

function period_cutoff(::SimModel)
    return (state::GamesOnNetworks.State) -> begin
        return period(state) >= 10000 #this is hard-coded now, but should add to state extra variables or something?
    end
end

const model = SimModel(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                        SimParams(10, 10, 0.1, "fractious_starting_condition", "equity_behavioral", extra=Dict{Symbol, Any}(:period_count=>0)),
                        CompleteModel())

models = SimModels(Game{3, 3}("Bargaining Game", payoff_matrix),
SimParams(10, 10, 0.1),
CompleteModel(),
FractiousState(),
PeriodCutoff(10500000), count=5)

@code_warntype simulate(model)

# @code_warntype GamesOnNetworks._simulate_model_barrier(model, nothing)
@code_warntype GamesOnNetworks._simulate_model_barrier(model, GamesOnNetworks.SETTINGS.database)

@code_warntype GamesOnNetworks._simulate_distributed_barrier(model)

@code_warntype GamesOnNetworks._simulate_distributed_barrier(model, GamesOnNetworks.SETTINGS.database, model_id=1)



@code_warntype GamesOnNetworks.State(model) #sketch

const state = GamesOnNetworks.State(model)
@code_warntype GamesOnNetworks._simulate(model, state)
@code_warntype GamesOnNetworks._simulate(model, state, GamesOnNetworks.SETTINGS.database, model_id=1)

@code_warntype GamesOnNetworks.is_stopping_condition(state, stoppingcondition(model))

@code_warntype GamesOnNetworks.run_period!(model, state)

@code_warntype GamesOnNetworks.calculate_expected_utilities!(model, state)

@code_warntype GamesOnNetworks.payoff_matrix(model)
const g = game(model)
@code_warntype GamesOnNetworks.payoff_matrix(g)

@code_warntype(GamesOnNetworks.components(state))

@code_warntype GamesOnNetworks.make_choices!(model, state)
@code_warntype GamesOnNetworks.rational_choice!(GamesOnNetworks.players(state, 1), GamesOnNetworks.maximum_strategy(GamesOnNetworks.expected_utilities(state, 2)))
@code_warntype GamesOnNetworks.maximum_strategy(GamesOnNetworks.expected_utilities(state, 2))
@code_warntype GamesOnNetworks.players(state, 1)

function testtt(model::SimModel, state::GamesOnNetworks.State)
    GamesOnNetworks._simulate(model, state)
    GamesOnNetworks.period!(state, 0)
end

function testt(model::SimModel)
    @timeit GamesOnNetworks.to "outer" simulate(model)
end