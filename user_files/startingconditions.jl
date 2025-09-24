@startingcondition function fractious_starting_condition(state::State)
    m = model(state)
    for (vertex, agent) in enumerate(agents(state))
        if vertex % 2 == 0
            recollection = strategies(m, 1)[1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
            Interactions.rational_choice!(agent, strategies(m, 1)[3])
        else
            recollection = strategies(m, 1)[3]
            Interactions.rational_choice!(agent, strategies(m, 1)[1])
        end
        for _ in 1:parameters(m, :memory_length)
            push!(Interactions.memory(agent), recollection)
        end
    end
    return nothing
end

@startingcondition function equity_starting_condition(state::State)
    m = model(state)
    for agent in agents(agents(state))
        recollection = strategies(m, 1)[2]
        for _ in 1:memory_length(m)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

@startingcondition function random_starting_condition(state::State)
    m = model(state)
    for agent in agents(state)
        # empty!(memory(agent)) #NOTE: make sure these arent needed (shouldnt be because agentgraph is initialized with these values when state is initialized. When state is reconstructed, starting condition isn't used anyway)
        # rational_choice!(agent, Choice(0))
        # choice!(agent, Choice(0))
        for _ in 1:memory_length(m)
            push!(memory(agent), random_strategy(m, 1))
        end
        Interactions.rational_choice!(agent, random_strategy(m, 1))
    end
    return nothing
end