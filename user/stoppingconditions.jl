@stoppingcondition function equity_stopping_condition(model::Model) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    sufficient_equity = (1 - error_rate(model)) * memory_length(model)
    sufficient_transitioned = number_agents(model) # - number_hermits(model)
    
    return (state::State) -> begin
        number_transitioned = 0
        for agent in agents(state)
            if !ishermit(agent)
                if count_strategy(Interactions.memory(agent), 2) >= sufficient_equity
                    number_transitioned += 1
                end
            end
        end 
        return number_transitioned >= sufficient_transitioned - number_hermits(state)
    end
end

@stoppingcondition function partially_reinforced_equity_stopping_condition(model::Model) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    sufficient_transitioned = (1 - error_rate(model)) * number_agents(model) # - number_hermits(model))
    period_cutoff = memory_length(model)

    return (state::State) -> begin
        number_transitioned = 0
        for agent in agents(state)
            if !ishermit(agent)
                if Interactions.rational_choice(agent) == 2 #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
                    number_transitioned += 1
                end
            end
        end 

        if number_transitioned >= sufficient_transitioned - number_hermits(state)
            set_user_variable!(state, :period_count, user_variables(state, :period_count) + 1)
            return user_variables(state, :period_count) >= period_cutoff
        else
            set_user_variable!(state, :period_count, 0)
            return false
        end
    end
end

@stoppingcondition function period_cutoff_stopping_condition(::Model)
    return (state::State) -> begin
        return period(state) >= user_variables(state, :period_cutoff) #this is hard-coded now, but should add to state extra variables or something?
    end
end