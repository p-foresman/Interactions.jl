#analytical algorithm to find threshold in simulated time-series data
#*** find the highest point that is returned to once it is crossed?
# or, based on a number of samples, at which point is the fraction_M unlikely to return to 0 (get highest that returns to 0 for each and take average?)
function find_threshold(db_filepath::String; group_id::Integer, plot_title::String="")
    sim_info_df, agent_df = querySimulationsForTimeSeries(db_filepath, group_id=group_id)
    payoff_matrix_size = JSON3.read(sim_info_df[1, :payoff_matrix_size], Tuple)
    payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
    # reproduced_game = JSON3.read(sim_info_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})
    agent_dict = OrderedDict()
    for row in eachrow(agent_df)
        if !haskey(agent_dict, row.period)
            agent_dict[row.period] = []
        end
        agent = JSON3.read(row.agent, Agent)
        # agent_memory = agent.memory
        # agent_behavior = determineAgentBehavior(reproduced_game, agent_memory) #old
        push!(agent_dict[row.period], rational_choice(agent))
    end
    period_counts = Vector()
    fraction_L = Vector()
    fraction_M = Vector()
    fraction_H = Vector()
    # current_peak = Vector()
    # threshold = 0.0
    # last_fraction_m = 0.0
    for (period, agent_behaviors) in agent_dict
        push!(period_counts, period)
        # subfractions = Vector()
        fraction_m = count(action->(action==2), agent_behaviors) / sim_info_df[1, :number_agents]
        push!(fraction_L, count(action->(action==3), agent_behaviors) / sim_info_df[1, :number_agents])
        push!(fraction_M, fraction_m)
        push!(fraction_H, count(action->(action==1), agent_behaviors) / sim_info_df[1, :number_agents])

        # push!(current_peak, fraction_m)
        # if fraction_m < threshold
        # if fraction_m < last_fraction_m && last_fraction_m > threshold
        #     peaks = last_fraction_m
        # end
        # last_fraction_m = fraction_m

        # println("$period: $subfractions")
        # push!(fractions, subfractions)
    end

    threshold = 0.0
    index_cutoff = findlast(i -> i == 0.0, fraction_M)
    println(index_cutoff)
    threshold = maximum(fraction_M[1:index_cutoff])
    # for m in fraction_M #find last 0 and find the max before it?

    # end

    # time_series_plot = plot(period_counts,
    #                         [fraction_H fraction_M fraction_L],
    #                         ylims=(0.0, 1.0),
    #                         layout=(3, 1),
    #                         legend=false,
    #                         title=[plot_title "" ""], 
    #                         xlabel=["" "" "Periods Elapsed"],
    #                         xticks=[:none :none :auto],
    #                         ylabel=["Proportion H" "Proportion M" "Proportion L"],
    #                         size=(700, 700))
    # return time_series_plot, threshold, fraction_M
end