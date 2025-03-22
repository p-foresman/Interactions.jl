@startingcondition function fractious_starting_condition(model::Model, agentgraph::AgentGraph)
    for (vertex, agent) in enumerate(agents(agentgraph))
        if vertex % 2 == 0
            recollection = strategies(model, 1)[1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
            Interactions.rational_choice!(agent, strategies(model, 1)[3])
        else
            recollection = strategies(model, 1)[3]
            Interactions.rational_choice!(agent, strategies(model, 1)[1])
        end
        for _ in 1:memory_length(model)
            push!(Interactions.memory(agent), recollection)
        end
    end
    return nothing
end

@startingcondition function equity_starting_condition(model::Model, agentgraph::AgentGraph)
    for agent in agents(agentgraph)
        recollection = strategies(model, 1)[2]
        for _ in 1:memory_length(model)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

@startingcondition function random_starting_condition(model::Model, agentgraph::AgentGraph)
    for agent in agents(agentgraph)
        # empty!(memory(agent)) #NOTE: make sure these arent needed (shouldnt be because agentgraph is initialized with these values when state is initialized. When state is reconstructed, starting condition isn't used anyway)
        # rational_choice!(agent, Choice(0))
        # choice!(agent, Choice(0))
        for _ in 1:memory_length(model)
            push!(memory(agent), random_strategy(model, 1))
        end
        Interactions.rational_choice!(agent, random_strategy(model, 1))
    end
    return nothing
end