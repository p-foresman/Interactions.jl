#Plotting for box plot (all network classes)
function transitionTimesBoxPlot(db_filepath::String;
    game_id::Integer,
    number_agents::Integer,
    memory_length::Integer,
    error::Float64,
    graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
    x_labels,
    colors,
    sample_size::Integer
)
df = querySimulationsForBoxPlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length=memory_length, error=error, graph_ids=graph_ids, sample_size=sample_size)
transition_times_matrix = zeros(sample_size, length(graph_ids))
println(df)
for (graph_number, graph_id) in enumerate(graph_ids)
filtered_df = filter(:graph_id => id -> id == graph_id, df)
transition_times_matrix[:, graph_number] = filtered_df[:, :periods_elapsed]
end
# colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2]] #palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]
# x_vals = ["Complete" "ER λ=1" "ER λ=5"] #"SW" "SF α=2" "SF α=4" "SF α=8" "SBM"
sim_plot = boxplot(x_labels,
transition_times_matrix,
leg = false,
yscale = :log10,
xlabel = "Graph",
ylabel = "Transtition Time (periods)",
fillcolor = colors,
size=(1800, 700),
left_margin=10Plots.mm,
right_margin=10Plots.mm,
bottom_margin=10Plots.mm)

return sim_plot
end


#Plotting for violin plot (all network classes)
function transitionTimesViolinPlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, x_labels, colors, sample_size::Integer)
df = Database.querySimulationsForBoxPlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length=memory_length, error=error, graph_ids=graph_ids, sample_size=sample_size)
transition_times_matrix = zeros(sample_size, length(graph_ids))
println(df)
for (graph_number, graph_id) in enumerate(graph_ids)
filtered_df = filter(:graph_id => id -> id == graph_id, df)
transition_times_matrix[:, graph_number] = filtered_df[:, :periods_elapsed]
end
# colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2]] #palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]
# x_vals = ["Complete" "ER λ=1" "ER λ=5"] #"SW" "SF α=2" "SF α=4" "SF α=8" "SBM"
sim_plot = violin(x_labels,
transition_times_matrix,
leg = false,
yscale = :log10,
xlabel = "Graph",
ylabel = "Transtition Time (periods)",
fillcolor = colors,
size=(1800, 700),
left_margin=10Plots.mm,
right_margin=10Plots.mm,
bottom_margin=10Plots.mm)

boxplot!(x_labels, transition_times_matrix, fillcolor=palette(:default)[5], fillalpha=0.4)
dotplot!(x_labels, transition_times_matrix, markercolor=:black)

return sim_plot
end


#Plotting for violin plot (all network classes)
function transitionTimesBoxPlot_populationSweep(db_filepath::String; game_id::Integer, graph_id::Integer, memory_length::Integer, number_agents::Union{Vector{<:Integer}, Nothing} = nothing, error::Float64, x_labels, colors, sample_size::Integer)
df = querySimulationsForBoxPlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length=memory_length, error=error, graph_ids=graph_ids, sample_size=sample_size)
transition_times_matrix = zeros(sample_size, length(graph_ids))
println(df)
for (graph_number, graph_id) in enumerate(graph_ids)
filtered_df = filter(:graph_id => id -> id == graph_id, df)
transition_times_matrix[:, graph_number] = filtered_df[:, :periods_elapsed]
end
# colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2]] #palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]
# x_vals = ["Complete" "ER λ=1" "ER λ=5"] #"SW" "SF α=2" "SF α=4" "SF α=8" "SBM"
sim_plot = boxplot(x_labels,
transition_times_matrix,
leg = false,
yscale = :log10,
xlabel = "Graph",
ylabel = "Transtition Time (periods)",
fillcolor = colors,
size=(1800, 700),
left_margin=10Plots.mm,
right_margin=10Plots.mm,
bottom_margin=10Plots.mm)

return sim_plot
end



function memoryLengthTransitionTimeLinePlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer, conf_intervals::Bool = false, conf_level::AbstractFloat = 0.95, bootstrap_samples::Integer = 1000, legend_labels::Vector = [], colors::Vector = [], error_styles::Vector = [], plot_title::String=nothing)
memory_length_list !== nothing ? memory_length_list = sort(memory_length_list) : nothing
errors !== nothing ? errors = sort(errors) : nothing
graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing

#initialize plot
x_label = "Memory Length"
x_lims = (minimum(memory_length_list) - 1, maximum(memory_length_list) + 1)
x_ticks = minimum(memory_length_list) - 1:1:maximum(memory_length_list) + 1

legend_labels_map = Dict()
for (index, graph_id) in enumerate(graph_ids)
legend_labels_map[graph_id] = legend_labels[index]
end

colors_map = Dict()
for (index, graph_id) in enumerate(graph_ids)
colors_map[graph_id] = colors[index]
end

error_styles_map = Dict()
for (index, error) in enumerate(errors)
error_styles_map[error] = error_styles[index]
end

sim_plot = plot(xlabel = x_label,
xlims = x_lims,
xticks = x_ticks,
ylabel = "Transition Time",
yscale = :log10,
legend_position = :outertopright,
size=(1300, 700),
left_margin=10Plots.mm,
bottom_margin=10Plots.mm,
title=plot_title)


#wrangle data
df = querySimulationsForMemoryLengthLinePlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length_list=memory_length_list, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
plot_line_number = 1 #this will make the lines unordered***
graph_id_number = 1
for graph_id in graph_ids
error_number = 1
for error in errors
filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)

average_memory_lengths = Vector{Float64}([])

conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
for (index, memory_length) in enumerate(memory_length_list)
filtered_df_per_len = filter(:memory_length => len -> len == memory_length, filtered_df)

confidence_interval = confint(bootstrap(mean, filtered_df_per_len.periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

push!(average_memory_lengths, confidence_interval[1]) #first element is the mean
push!(confidence_interval_lower, confidence_interval[2])
push!(confidence_interval_upper, confidence_interval[3])
end

# error_number == 1 ? legend_label = legend_labels_map[graph_id] : legend_label = nothing
legend_label = "$(legend_labels_map[graph_id]), error=$error"

plot!(memory_length_list, average_memory_lengths, markershape = :circle, markercolor=colors_map[graph_id], linecolor=colors_map[graph_id], linestyle=error_styles_map[error][1], label=legend_label)

if conf_intervals
plot!(memory_length_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, fillcolor=colors_map[graph_id], fillstyle=error_styles_map[error][2], label=nothing)
end

plot_line_number += 1
error_number += 1
end
graph_id_number += 1
end
return sim_plot
end




# function numberAgentsTransitionTimeLinePlot(db_filepath::String;
#                                             game_id::Integer,
#                                             number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
#                                             memory_length::Integer,
#                                             errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
#                                             graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
#                                             sample_size::Integer, conf_intervals::Bool = false,
#                                             conf_level::AbstractFloat = 0.95,
#                                             bootstrap_samples::Integer = 1000,
#                                             legend_labels::Vector = [],
#                                             colors::Vector = [],
#                                             error_styles::Vector = [],
#                                             plot_title::String=nothing)

#     number_agents_list !== nothing ? number_agents_list = sort(number_agents_list) : nothing
#     errors !== nothing ? errors = sort(errors) : nothing
#     graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing


#     #initialize plot
#     x_label = "Number Agents"
#     x_lims = (minimum(number_agents_list) - 10, maximum(number_agents_list) + 10)
#     x_ticks = minimum(number_agents_list) - 10:10:maximum(number_agents_list) + 10

#     legend_labels_map = Dict()
#     for (index, graph_id) in enumerate(graph_ids)
#         legend_labels_map[graph_id] = legend_labels[index]
#     end

#     colors_map = Dict()
#     for (index, graph_id) in enumerate(graph_ids)
#         colors_map[graph_id] = colors[index]
#     end

#     error_styles_map = Dict()
#     for (index, error) in enumerate(errors)
#         error_styles_map[error] = error_styles[index]
#     end

#     sim_plot = plot(xlabel = x_label,
#                     xlims = x_lims,
#                     xticks = x_ticks,
#                     ylabel = "Transition Time",
#                     yscale = :log10,
#                     legend_position = :outertopright,
#                     size=(1300, 700),
#                     left_margin=10Plots.mm,
#                     bottom_margin=10Plots.mm,
#                     title=plot_title)


#     #wrangle data
#     df = querySimulationsForNumberAgentsLinePlot(db_filepath, game_id=game_id, number_agents_list=number_agents_list, memory_length=memory_length, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
#     plot_line_number = 1 #this will make the lines unordered***
#     for graph_id in graph_ids
#         for error in errors
#             filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)

#             average_number_agents = Vector{Float64}([])

#             conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
#             conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
#             for (index, number_agents) in enumerate(number_agents_list)
#                 filtered_df_per_num = filter(:number_agents => num -> num == number_agents, filtered_df)

#                 confidence_interval = confint(bootstrap(mean, filtered_df_per_num.periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

#                 push!(average_number_agents, confidence_interval[1]) #first element is the mean
#                 push!(confidence_interval_lower, confidence_interval[2])
#                 push!(confidence_interval_upper, confidence_interval[3])
#             end

#             legend_label = "$(legend_labels_map[graph_id]), error=$error"

#             plot!(number_agents_list, average_number_agents, markershape = :circle, markercolor=colors_map[graph_id], linecolor=colors_map[graph_id], linestyle=error_styles_map[error][1], label=legend_label)

#             if conf_intervals
#                 plot!(number_agents_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, fillcolor=colors_map[graph_id], fillstyle=error_styles_map[error][2], label=nothing)
#             end

#             plot_line_number += 1
#         end
#     end
#     return sim_plot
# end



function timeSeriesPlot(db_filepath::String; sim_group_id::Integer, plot_title::String = "")
sim_info_df, agent_df = querySimulationsForTimeSeries(db_filepath, sim_group_id=sim_group_id)
payoff_matrix_size = JSON3.read(sim_info_df[1, :payoff_matrix_size], Tuple)
payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
reproduced_game = JSON3.read(sim_info_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})
agent_dict = OrderedDict()
for row in eachrow(agent_df)
if !haskey(agent_dict, row.periods_elapsed)
agent_dict[row.periods_elapsed] = []
end
agent = JSON3.read(row.agent, Agent)
# agent_memory = agent.memory
# agent_behavior = determineAgentBehavior(reproduced_game, agent_memory) #old
push!(agent_dict[row.periods_elapsed], rational_choice(agent))
end
period_counts = Vector()
fraction_L = Vector()
fraction_M = Vector()
fraction_H = Vector()
# fractions = Vector()
for (periods_elapsed, agent_behaviors) in agent_dict
push!(period_counts, periods_elapsed)
# subfractions = Vector()
push!(fraction_L, count(action->(action==3), agent_behaviors) / sim_info_df[1, :number_agents])
push!(fraction_M, count(action->(action==2), agent_behaviors) / sim_info_df[1, :number_agents])
push!(fraction_H, count(action->(action==1), agent_behaviors) / sim_info_df[1, :number_agents])
# println("$periods_elapsed: $subfractions")
# push!(fractions, subfractions)
end
time_series_plot = plot(period_counts,
[fraction_H fraction_M fraction_L],
ylims=(0.0, 1.0),
layout=(3, 1),
legend=false,
title=[plot_title "" ""], 
xlabel=["" "" "Periods Elapsed"],
xticks=[:none :none :auto],
ylabel=["Proportion H" "Proportion M" "Proportion L"],
size=(700, 700))
return time_series_plot
end


#NOTE: CORRECT FOR HERMITS!! AND CUT OFF BEGINNING (period 0 isn't stored, but should be)!
function multipleTimeSeriesPlot(db_filepath::String; sim_group_ids::Vector{<:Integer}, labels::Union{Vector{String}, Nothing} = nothing, plot_title::String = "")
time_series_plot = plot(
ylims=(0.0, 1.0),
layout=(3, 1),
legend=[true false false],
title=[plot_title "" ""], 
xlabel=["" "" "Periods Elapsed"],
xticks=[:none :none :auto],
ylabel=["Proportion H" "Proportion M" "Proportion L"],
size=(1000, 1500))
for (i, sim_group_id) in enumerate(sim_group_ids)
sim_info_df, agent_df = querySimulationsForTimeSeries(db_filepath, sim_group_id=sim_group_id)
payoff_matrix_size = JSON3.read(sim_info_df[1, :payoff_matrix_size], Tuple)
payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
# reproduced_game = JSON3.read(sim_info_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})
agent_dict = OrderedDict()
hermit_count = 0
for (row_num, row) in enumerate(eachrow(agent_df))
if !haskey(agent_dict, row.periods_elapsed)
agent_dict[row.periods_elapsed] = []
end
agent = JSON3.read(row.agent, Agent)
# agent_memory = agent.memory
# agent_behavior = determineAgentBehavior(reproduced_game, agent_memory) #old
if !ishermit(agent) #if the agent is a hermit, it shouldn't count in the population
push!(agent_dict[row.periods_elapsed], rational_choice(agent))
else
if row_num == 1
hermit_count += 1
end
end
end
period_counts = Vector()
fraction_L = Vector()
fraction_M = Vector()
fraction_H = Vector()
# fractions = Vector()
for (periods_elapsed, agent_behaviors) in agent_dict
push!(period_counts, periods_elapsed)
# subfractions = Vector()
push!(fraction_L, count(action->(action==3), agent_behaviors) / (sim_info_df[1, :number_agents] - hermit_count))
push!(fraction_M, count(action->(action==2), agent_behaviors) / (sim_info_df[1, :number_agents] - hermit_count))
push!(fraction_H, count(action->(action==1), agent_behaviors) / (sim_info_df[1, :number_agents] - hermit_count))
# println("$periods_elapsed: $subfractions")
# push!(fractions, subfractions)
end
label = labels !== nothing ? labels[i] : nothing
time_series_plot = plot!(period_counts,
    [fraction_H fraction_M fraction_L],
    label=label,
    linewidth=2)
end
return time_series_plot
end




# function memoryLengthTransitionTimeLinePlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
#     memory_length_list !== nothing ? memory_length_list = sort(memory_lengths) : nothing
#     errors !== nothing ? errors = sort(errors) : nothing
#     graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing

#     df = querySimulationsForMemoryLengthLinePlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length_list=memory_length_list, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
#     println(df)
#     line_count = length(errors) * length(graph_ids)
#     println("line count: " * "$line_count")
#     series_matrix = zeros(length(memory_length_list), line_count) #this is an issue if memory_lengths/errors/graph_ids=nothing***
#     plot_line_number = 1 #this will make the lines unordered***

#     println(series_matrix)
#     legend_labels = Matrix(undef, 1, line_count)
#     for graph_id in graph_ids
#         for error in errors
#             legend_labels[1, plot_line_number] = "graph: $graph_id, error: $error"
#             filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)
#             average_memory_lengths = zeros(length(memory_length_list))
#             for (index, memory_length) in enumerate(memory_length_list)
#                 filtered_df_per_len = filter(:memory_length => len -> len == memory_length, filtered_df)
#                 average_memory_lengths[index] = mean(filtered_df_per_len.periods_elapsed)
#             end
#             series_matrix[:, plot_line_number] = average_memory_lengths
#             plot_line_number += 1
#         end
#     end
#     println(legend_labels)
#     println(series_matrix)

#     # println("plot line number: " * "$plot_line_number")

#     x_label = "Memory Length"
#     x_lims = (minimum(memory_length_list) - 1, maximum(memory_length_list) + 1)
#     x_ticks = minimum(memory_length_list) - 1:1:maximum(memory_length_list) + 1

#     sim_plot = plot(memory_length_list,
#                     series_matrix,
#                     label = legend_labels,
#                     xlabel = x_label,
#                     xlims = x_lims,
#                     xticks = x_ticks,
#                     ylabel = "Transition Time",
#                     yscale = :log10,
#                     legend_position = :topleft,
#                     linestyle = :solid,
#                     markershape = :circle)

#     return sim_plot
# end

"""
    function noise_vs_structure_heatmap(db_info::Database.DBInfo=SETTINGS.database;
            game_id::Integer,
            graphmodel_extra::Vector{<:Dict{Symbol, Any}},
            errors::Vector{<:AbstractFloat},
            mean_degrees::Vector{<:AbstractFloat},
            number_agents::Integer,
            memory_length::Integer,
            startingcondition_id::Integer,
            stoppingcondition_id::Integer,
            sample_size::Integer,
            legend_labels::Vector = [],
            colors::Vector = [],
            error_styles::Vector = [],
            plot_title::String="", 
            bootstrap_samples::Integer=1000)

If no positional argument given, configured database is used.
"""
function noise_vs_structure_heatmap(db_info::Database.DBInfo=SETTINGS.database;
                                    game_id::Integer,
                                    graphmodel_extra::Vector{<:Dict{Symbol, Any}},
                                    error_rates::Vector{<:AbstractFloat},
                                    mean_degrees::Vector{<:AbstractFloat},
                                    number_agents::Integer,
                                    memory_length::Integer,
                                    starting_condition::String,
                                    stopping_condition::String,
                                    sample_size::Integer,
                                    legend_labels::Vector = [],
                                    colors::Vector = [],
                                    error_styles::Vector = [],
                                    plot_title::String="", 
                                    bootstrap_samples::Integer=1000,
                                    filename::String="")

    # sort!(graph_ids)
    # sort!(error_rates)
    # sort!(mean_degrees)


    x = string.(mean_degrees)
    y = string.(error_rates)
    # x_axis = fill(string.(mean_degrees), (length(graph_ids), 1))
    # y_axis = fill(string.(error_rates), (length(graph_ids), 1))

    # graphmodel_list = [:λ, :β, :α, :blocks, :p_in, :p_out]
    # for graph in graphmodel
    #     for param in graphmodel_list
    #         if !(param in collect(keys(graph)))
    #             graph[param] = nothing
    #         end
    #     end
    # end
    graphmodel = Vector{Dict{Symbol, Any}}()
    for λ in mean_degrees
        for graph in graphmodel_extra
            g = deepcopy(graph)
            g[:λ] = λ
            delete!(g, :title)
            push!(graphmodel, g)
        end
    end
    println(graphmodel)

    # z_data = fill(zeros(length(mean_degrees), length(error_rates)), (1, length(graphmodel_extra)))
    # z_data = [zeros(length(mean_degrees), length(error_rates)) for _ in 1:length(graphmodel_extra)]
    z_data = zeros(length(error_rates), length(mean_degrees), length(graphmodel_extra))

    println(z_data)
    df = Database.execute_query_simulations_for_noise_structure_heatmap(db_info,
                                                                game_id=game_id,
                                                                graphmodel_params=graphmodel,
                                                                errors=error_rates,
                                                                mean_degrees=mean_degrees,
                                                                number_agents=number_agents,
                                                                memory_length=memory_length,
                                                                starting_condition=starting_condition,
                                                                stopping_condition=stopping_condition,
                                                                sample_size=sample_size)
    # return df
    for (graph_index, graph) in enumerate(graphmodel_extra)

        function graph_filter(graphmodel_type, β, α, p_in, p_out)
            graphmodel_type_match = graphmodel_type == graph[:type]
            β_match = haskey(graph, :β) ? β == graph[:β] : ismissing(β)
            α_match = haskey(graph, :α) ? α == graph[:α] : ismissing(α)
            p_in_match = haskey(graph, :p_in) ? p_in == graph[:p_in] : ismissing(p_in)
            p_out_match = haskey(graph, :p_out) ? p_out == graph[:p_out] : ismissing(p_out)
            return graphmodel_type_match && β_match && α_match && p_in_match && p_out_match
        end

        filtered_df = filter([:graphmodel_type, :β, :α, :p_in, :p_out] => graph_filter, df) #NOTE: this is filtering by graph graphmodel_type only, which is okay if there's only one of each graph type. Otherwise, need to change!!!
        # println(filtered_df)
        for (col, mean_degree) in enumerate(mean_degrees)
            for (row, error) in enumerate(error_rates)
            more_filtered = filter([:error, :λ] => (err, λ) -> err == error && λ == mean_degree, filtered_df)
            # println(more_filtered)
            # scaled_period = more_filtered.period ./ GraphsExt.edge_density(number_agents, mean_degree) #NOTE: REMOVE THIS]
            # scaled_period = more_filtered.period
            # scaled_period = (more_filtered.period .* GraphsExt.edge_density(number_agents, mean_degree) .* number_agents) / 2
            average_transition_time = mean(straps(bootstrap(mean, more_filtered.period, BasicSampling(bootstrap_samples)), 1)) #Gives the mean of the bootstrapped samples
            # average_transition_time = mean(more_filtered.period)
            # println(average_transition_time)
            # println("($row, $col, $graph_index)")
            z_data[row, col, graph_index] = average_transition_time
            # println(log10(average_transition_time))
            end
        end
    end

    # for i in eachindex(graphmodel_extra)
    #     println(z_data[:, :, i])
    # end

    #this stuff needs to be removed!
    # z_data = [zeros(length(mean_degrees), length(error_rates)) for _ in 1:length(graphmodel_extra)]
    # z_data = zeros(length(mean_degrees), length(error_rates), length(graphmodel_extra))
    # for i in eachindex(graphmodel_extra)
    #     for x in eachindex(mean_degrees)
    #         for y in eachindex(error_rates)
    #             z_data[i, x, y] = i + x + y
    #         end
    #     end
    # end
    # println(z_data)
    # return z_data
    clims_colorbar = extrema(z_data) #first get the extrema of the original data for the colorbar scale
    z_data = log10.(z_data) #then take the log of the data
    clims = extrema(z_data) #then get the extrema of the log of data for the heatmap colors
    # clims = (log10(10), log10(100000))
    # println(clims)

    plots = []
    # for z in z_data
    #     println(z)
    #     push!(plots, heatmap(x, y, z, clims=clims, c=:viridis, colorbar=false))
    # end
    for graph_index in eachindex(graphmodel_extra)
        # println(z_data[:, :, graph_index])
        title = "\n" * graphmodel_extra[graph_index][:title]
        # x_ticks = graph_index == length(graphmodel_extra)
        # x_label = x_ticks ? "Mean Degree" : ""
        x_ticks = true
        x_label = graph_index == length(graphmodel_extra) ? "Mean Degree" : ""
        push!(plots, heatmap(x, y, z_data[:, :, graph_index], clims=clims, c=:viridis, colorbar=false, title=title, xlabel=x_label, ylabel="Error", xticks=x_ticks))
    end

    push!(plots, scatter([0,0], [0,1], zcolor=[0,3], clims=clims_colorbar,
    xlims=(1,1.1), xshowaxis=false, yshowaxis=false, label="", c=:viridis, colorbar_scale=:log10, colorbar_title="Periods Elapsed", grid=false))

    # l = @layout [Plots.grid(length(z_data), 1) a{0.01w}]
    l = @layout [Plots.grid(length(graphmodel_extra), 1) a{0.01w}]
    full_plot = plot(plots..., layout=l, link=:all, size=(1000, 1000), left_margin=10Plots.mm, right_margin=10Plots.mm)
    # savefig(p_all, "shared_colorbar_julia.png")
    !isempty(filename) && png(full_plot, normpath(joinpath(SETTINGS.figure_dirpath, filename)))
    return full_plot
end



# function transition_times_vs_memory_sweep(db_filepath::String;
#                 game_id::Integer,
#                 memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing,
#                 number_agents::Integer,
#                 error_rates::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
#                 graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
#                 startingcondition_id::Integer,
#                 stoppingcondition_id::Integer,
#                 sample_size::Integer,
#                 conf_intervals::Bool = false,
#                 conf_level::AbstractFloat = 0.95,
#                 bootstrap_samples::Integer = 1000,
#                 legend_labels::Vector = [],
#                 colors::Vector = [],
#                 error_styles::Vector = [],
#                 plot_title::String="", 
#                 sim_plot::Union{Plots.Plot, Nothing}=nothing)

# memory_length_list !== nothing ? memory_length_list = sort(memory_length_list) : nothing
# error_rates !== nothing ? error_rates = sort(error_rates) : nothing
# graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing


# #initialize plot
# x_label = "Memory Length"
# x_lims = (minimum(memory_length_list) - 1, maximum(memory_length_list) + 1)
# x_ticks = minimum(memory_length_list) - 1:1:maximum(memory_length_list) + 1

# legend_labels_map = Dict()
# for (index, graph_id) in enumerate(graph_ids)
# legend_labels_map[graph_id] = legend_labels[index]
# end

# colors_map = Dict()
# for (index, graph_id) in enumerate(graph_ids)
# colors_map[graph_id] = colors[index]
# end

# # error_styles_map = Dict()
# # for (index, error) in enumerate(error_rates)
# #     error_styles_map[error] = error_styles[index]
# # end
# if sim_plot === nothing
# sim_plot = plot(xlabel = x_label,
# xlims = x_lims,
# xticks = x_ticks,
# ylabel = "Transition Time",
# yscale = :log10,
# legend_position = :topleft,
# size=(1300, 700),
# left_margin=10Plots.mm,
# bottom_margin=10Plots.mm,
# right_margin=10Plots.mm,
# title=plot_title,
# thickness_scaling=1.2
# )
# end


# #wrangle data
# df = query_simulations_for_transition_time_vs_memory_sweep(db_filepath,
#                                         game_id=game_id,
#                                         memory_length_list=memory_length_list,
#                                         number_agents=number_agents,
#                                         error_rates=error_rates,
#                                         graph_ids=graph_ids,
#                                         startingcondition_id=startingcondition_id,
#                                         stoppingcondition_id=stoppingcondition_id,
#                                         sample_size=sample_size)
# plot_line_number = 1 #this will make the lines unordered***
# for graph_id in graph_ids
# for error in error_rates
# filtered_df = filter([:error, :graph_id, :startingcondition_id, :stoppingcondition_id] => (err, graph, start, stop) -> err == error && graph == graph_id && start == startingcondition_id && stop == stoppingcondition_id, df)
# # println(filtered_df)
# average_transition_time = Vector{Float64}([])

# conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
# conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
# for (index, memory_length) in enumerate(memory_length_list)
# filtered_df_per_num = filter(:memory_length => num -> num == memory_length, filtered_df)
# # println(filtered_df_per_num)
# confidence_interval = confint(bootstrap(mean, filtered_df_per_num.periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

# push!(average_transition_time, confidence_interval[1]) #first element is the mean
# if conf_intervals
# push!(confidence_interval_lower, confidence_interval[2])
# push!(confidence_interval_upper, confidence_interval[3])
# end
# end

# legend_label = "$(legend_labels_map[graph_id])" #, error=$error"

# plot!(memory_length_list, average_transition_time, markershape = :circle, linewidth=2, label=legend_label, markercolor=colors_map[graph_id], linecolor=colors_map[graph_id])#, linestyle=error_styles_map[error][1])

# if conf_intervals
# plot!(memory_length_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, label=nothing, fillcolor=colors_map[graph_id])#, fillstyle=error_styles_map[error][2])
# end

# plot_line_number += 1
# end
# end
# return sim_plot
# end


# #NOTE: add a param for log scale or not
# function transition_times_vs_population_sweep(db_info::Database.DBInfo=SETTINGS.database;
#                     game_id::Integer,
#                     number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
#                     memory_length::Integer,
#                     error_rates::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
#                     graphmodel_ids::Union{Vector{<:Integer}, Nothing} = nothing,
#                     starting_condition::String,
#                     stopping_condition::String,
#                     sample_size::Integer,
#                     conf_intervals::Bool = false,
#                     conf_level::AbstractFloat = 0.95,
#                     bootstrap_samples::Integer = 1000,
#                     legend_labels::Vector = [],
#                     colors::Vector = [],
#                     error_styles::Vector = [],
#                     plot_title::String="", 
#                     sim_plot::Union{Plots.Plot, Nothing}=nothing)

#     number_agents_list !== nothing ? number_agents_list = sort(number_agents_list) : nothing
#     error_rates !== nothing ? error_rates = sort(error_rates) : nothing
#     graphmodel_ids !== nothing ? graphmodel_ids = sort(graphmodel_ids) : nothing


#     #initialize plot
#     x_label = "Population"
#     x_lims = (minimum(number_agents_list) - 10, maximum(number_agents_list) + 10)
#     x_ticks = minimum(number_agents_list) - 10:10:maximum(number_agents_list)# + 10

#     legend_labels_map = Dict()
#     for (index, graphmodel_id) in enumerate(graphmodel_ids)
#         legend_labels_map[graphmodel_id] = legend_labels[index]
#     end

#     colors_map = Dict()
#     for (index, graphmodel_id) in enumerate(graphmodel_ids)
#         colors_map[graphmodel_id] = colors[index]
#     end

#     # error_styles_map = Dict()
#     # for (index, error) in enumerate(error_rates)
#     #     error_styles_map[error] = error_styles[index]
#     # end
#     if sim_plot === nothing
#         sim_plot = plot(xlabel = x_label,
#                         xlims = x_lims,
#                         xticks = x_ticks,
#                         ylabel = "Transition Time",
#                         yscale = :log10,
#                         legend_position = :topleft,
#                         size=(1300, 700),
#                         left_margin=10Plots.mm,
#                         bottom_margin=10Plots.mm,
#                         right_margin=10Plots.mm,
#                         title=plot_title,
#                         thickness_scaling=1.2
#         )
#     end


#     #wrangle data
#     df = Database.query_simulations_for_transition_time_vs_population_sweep(db_info,
#                                             game_id=game_id,
#                                             number_agents_list=number_agents_list,
#                                             memory_length=memory_length,
#                                             error_rates=error_rates,
#                                             graphmodel_ids=graphmodel_ids,
#                                             starting_condition=starting_condition,
#                                             stopping_condition=stopping_condition,
#                                             sample_size=sample_size)
#     return df
#     plot_line_number = 1 #this will make the lines unordered***
#     for graphmodel_id in graphmodel_ids
#         for error in error_rates
#             filtered_df = filter([:error, :graphmodel_id, :starting_condition, :stopping_condition] => (err, graph, start, stop) -> err == error && graph == graphmodel_id && start == starting_condition && stop == stopping_condition, df)
#             # println(filtered_df)
#             average_transition_time = Vector{Float64}([])

#             conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
#             conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
#             for (index, number_agents) in enumerate(number_agents_list)
#                 filtered_df_per_num = filter(:number_agents => num -> num == number_agents, filtered_df)
#                 # println(filtered_df_per_num)
#                 mean_degree = filtered_df_per_num.λ[1] #all should be the same. NOTE: remove this
#                 scaled_periods_elapsed = filtered_df_per_num.period #NOTE: remove this
#                 if !ismissing(mean_degree) #NOTE: remove this
#                     scaled_periods_elapsed = scaled_periods_elapsed ./ edge_density(number_agents, mean_degree) #NOTE: REMOVE THIS
#                 end
#                 confidence_interval = confint(bootstrap(mean, scaled_periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

#                 push!(average_transition_time, confidence_interval[1]) #first element is the mean
#                 if conf_intervals
#                     push!(confidence_interval_lower, confidence_interval[2])
#                     push!(confidence_interval_upper, confidence_interval[3])
#                 end
#             end

#             legend_label = "$(legend_labels_map[graphmodel_id])" #, error=$error"

#             plot!(number_agents_list, average_transition_time, markershape=:circle, linewidth=2, label=legend_label, markercolor=colors_map[graphmodel_id], linecolor=colors_map[graphmodel_id])#, linestyle=error_styles_map[error][1])

#             if conf_intervals
#                 plot!(number_agents_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, label=nothing, fillcolor=colors_map[graphmodel_id])#, fillstyle=error_styles_map[error][2])
#             end

#             plot_line_number += 1
#         end
#     end
#     return sim_plot
# end



# function transition_times_vs_population_stopping_conditions(db_filepath::String;
#                                 game_id::Integer,
#                                 number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
#                                 memory_length::Integer,
#                                 errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
#                                 graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
#                                 startingcondition_ids::Vector{<:Integer},
#                                 stoppingcondition_ids::Vector{<:Integer},
#                                 sample_size::Integer,
#                                 conf_intervals::Bool = false,
#                                 conf_level::AbstractFloat = 0.95,
#                                 bootstrap_samples::Integer = 1000,
#                                 legend_labels::Vector = [],
#                                 colors::Vector = [],
#                                 error_styles::Vector = [],
#                                 plot_title::String="")

# number_agents_list !== nothing ? number_agents_list = sort(number_agents_list) : nothing
# errors !== nothing ? errors = sort(errors) : nothing
# graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing
# sort!(startingcondition_ids)
# sort!(stoppingcondition_ids)


# #initialize plot
# x_label = "Population"
# x_lims = (minimum(number_agents_list) - 10, maximum(number_agents_list) + 10)
# x_ticks = minimum(number_agents_list) - 10:10:maximum(number_agents_list) + 10

# legend_labels_map = Dict()
# for (index, stoppingcondition_id) in enumerate(stoppingcondition_ids)
# legend_labels_map[stoppingcondition_id] = legend_labels[index]
# end

# colors_map = Dict()
# for (index, stoppingcondition_id) in enumerate(stoppingcondition_ids)
# colors_map[stoppingcondition_id] = colors[index]
# end

# # error_styles_map = Dict()
# # for (index, error) in enumerate(errors)
# #     error_styles_map[error] = error_styles[index]
# # end

# sim_plot = plot(xlabel = x_label,
# xlims = x_lims,
# xticks = x_ticks,
# ylabel = "Transition Time",
# yscale = :log10,
# legend_position = :topleft,
# size=(1300, 700),
# left_margin=10Plots.mm,
# bottom_margin=10Plots.mm,
# right_margin=10Plots.mm,
# title=plot_title,
# thickness_scaling=1.2)


# #wrangle data
# df = query_simulations_for_transition_time_vs_population_stopping_condition(db_filepath,
#                                                     game_id=game_id,
#                                                     number_agents_list=number_agents_list,
#                                                     memory_length=memory_length,
#                                                     errors=errors,
#                                                     graph_ids=graph_ids,
#                                                     startingcondition_ids=startingcondition_ids,
#                                                     stoppingcondition_ids=stoppingcondition_ids,
#                                                     sample_size=sample_size)
# plot_line_number = 1 #this will make the lines unordered***
# for graph_id in graph_ids
# for error in errors
# for startingcondition_id in startingcondition_ids
# for stoppingcondition_id in stoppingcondition_ids
# filtered_df = filter([:error, :graph_id, :startingcondition_id, :stoppingcondition_id] => (err, graph, start, stop) -> err == error && graph == graph_id && start == startingcondition_id && stop == stoppingcondition_id, df)
# # println(filtered_df)
# average_transition_time = Vector{Float64}([])

# conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
# conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
# for (index, number_agents) in enumerate(number_agents_list)
# filtered_df_per_num = filter(:number_agents => num -> num == number_agents, filtered_df)
# # println(filtered_df_per_num)
# confidence_interval = confint(bootstrap(mean, filtered_df_per_num.periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

# push!(average_transition_time, confidence_interval[1]) #first element is the mean
# if conf_intervals
# push!(confidence_interval_lower, confidence_interval[2])
# push!(confidence_interval_upper, confidence_interval[3])
# end
# end

# legend_label = "$(legend_labels_map[stoppingcondition_id]), error=$error"

# plot!(number_agents_list, average_transition_time, markershape = :circle, linewidth=2, label=legend_label, markercolor=colors_map[stoppingcondition_id], linecolor=colors_map[stoppingcondition_id])#, linestyle=error_styles_map[error][1])

# if conf_intervals
# plot!(number_agents_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, label=nothing, fillcolor=colors_map[stoppingcondition_id])#, fillstyle=error_styles_map[error][2])
# end

# plot_line_number += 1
# end
# end
# end
# end
# return sim_plot
# end

# function transition_times_vs_memory_length_stopping_conditions(db_filepath::String;
#                                 game_id::Integer,
#                                 memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing,
#                                 number_agents::Integer,
#                                 errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
#                                 graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
#                                 startingcondition_ids::Vector{<:Integer},
#                                 stoppingcondition_ids::Vector{<:Integer},
#                                 sample_size::Integer,
#                                 conf_intervals::Bool = false,
#                                 conf_level::AbstractFloat = 0.95,
#                                 bootstrap_samples::Integer = 1000,
#                                 legend_labels::Vector = [],
#                                 colors::Vector = [],
#                                 error_styles::Vector = [],
#                                 plot_title::String="")

# memory_length_list !== nothing ? memory_length_list = sort(memory_length_list) : nothing
# errors !== nothing ? errors = sort(errors) : nothing
# graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing
# sort!(startingcondition_ids)
# sort!(stoppingcondition_ids)


# #initialize plot
# x_label = "Memory Length"
# x_lims = (minimum(memory_length_list) - 1, maximum(memory_length_list) + 1)
# x_ticks = minimum(memory_length_list) - 1:1:maximum(memory_length_list) + 1

# legend_labels_map = Dict()
# for (index, stoppingcondition_id) in enumerate(stoppingcondition_ids)
# legend_labels_map[stoppingcondition_id] = legend_labels[index]
# end

# colors_map = Dict()
# for (index, stoppingcondition_id) in enumerate(stoppingcondition_ids)
# colors_map[stoppingcondition_id] = colors[index]
# end

# # error_styles_map = Dict()
# # for (index, error) in enumerate(errors)
# #     error_styles_map[error] = error_styles[index]
# # end

# sim_plot = plot(xlabel = x_label,
# xlims = x_lims,
# xticks = x_ticks,
# ylabel = "Transition Time",
# yscale = :log10,
# legend_position = :topleft,
# size=(1300, 700),
# left_margin=10Plots.mm,
# bottom_margin=10Plots.mm,
# right_margin=10Plots.mm,
# title=plot_title,
# thickness_scaling=1.2)


# #wrangle data
# df = query_simulations_for_transition_time_vs_memory_length_stopping_condition(db_filepath,
#                                                     game_id=game_id,
#                                                     memory_length_list=memory_length_list,
#                                                     number_agents=number_agents,
#                                                     errors=errors,
#                                                     graph_ids=graph_ids,
#                                                     startingcondition_ids=startingcondition_ids,
#                                                     stoppingcondition_ids=stoppingcondition_ids,
#                                                     sample_size=sample_size)
# plot_line_number = 1 #this will make the lines unordered***
# for graph_id in graph_ids
# for error in errors
# for startingcondition_id in startingcondition_ids
# for stoppingcondition_id in stoppingcondition_ids
# filtered_df = filter([:error, :graph_id, :startingcondition_id, :stoppingcondition_id] => (err, graph, start, stop) -> err == error && graph == graph_id && start == startingcondition_id && stop == stoppingcondition_id, df)
# # println(filtered_df)
# average_transition_time = Vector{Float64}([])

# conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
# conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
# for (index, memory_length) in enumerate(memory_length_list)
# filtered_df_per_num = filter(:memory_length => num -> num == memory_length, filtered_df)
# # println(filtered_df_per_num)
# confidence_interval = confint(bootstrap(mean, filtered_df_per_num.periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

# push!(average_transition_time, confidence_interval[1]) #first element is the mean
# if conf_intervals
# push!(confidence_interval_lower, confidence_interval[2])
# push!(confidence_interval_upper, confidence_interval[3])
# end
# end

# legend_label = "$(legend_labels_map[stoppingcondition_id]), error=$error"

# plot!(memory_length_list, average_transition_time, markershape = :circle, linewidth=2, label=legend_label, markercolor=colors_map[stoppingcondition_id], linecolor=colors_map[stoppingcondition_id])#, linestyle=error_styles_map[error][1])

# if conf_intervals
# plot!(memory_length_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, label=nothing, fillcolor=colors_map[stoppingcondition_id])#, fillstyle=error_styles_map[error][2])
# end

# plot_line_number += 1
# end
# end
# end
# end
# return sim_plot
# end





function transition_times_vs_graphmodel_sweep(db_filepath::String;
                game_id::Integer,
                memory_length::Integer,
                number_agents::Integer,
                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                graphmodel_extra::Vector{<:Dict{Symbol, Any}},
                sweep_param::Symbol,
                startingcondition_id::Integer,
                stoppingcondition_id::Integer,
                sample_size::Integer,
                conf_intervals::Bool = false,
                conf_level::AbstractFloat = 0.95,
                bootstrap_samples::Integer = 1000,
                legend_labels::Vector = [],
                colors::Vector = [],
                error_styles::Vector = [],
                plot_title::String="", 
                sim_plot::Union{Plots.Plot, Nothing}=nothing)

errors !== nothing ? errors = sort(errors) : nothing

graphmodel = Vector{Dict{Symbol, Any}}()
sweep_param_values = []
for graph in graphmodel_extra
g = deepcopy(graph)
# delete!(g, :title)
push!(graphmodel, g)
push!(sweep_param_values, g[sweep_param]) #for finding xlims
end
println(graphmodel)

#initialize plot
x_label = string(sweep_param)
# x_lims = (minimum(sweep_param_values) - 1, maximum(sweep_param_values) + 1)
# x_ticks = minimum(sweep_param_values) - 1:1:maximum(sweep_param_values) + 1
x_lims = (2, 11)
x_ticks = 2:1:11

legend_labels_map = Dict()
for index in eachindex(errors)
legend_labels_map[index] = legend_labels[index]
end

colors_map = Dict()
for index in eachindex(errors)
colors_map[index] = colors[index]
end

# error_styles_map = Dict()
# for (index, error) in enumerate(errors)
#     error_styles_map[error] = error_styles[index]
# end
if isnothing(sim_plot)
sim_plot = plot(xlabel = x_label,
xlims = x_lims,
xticks = x_ticks,
ylabel = "Transition Time",
yscale = :log10,
legend_position = :topleft,
size=(1300, 700),
left_margin=10Plots.mm,
bottom_margin=10Plots.mm,
right_margin=10Plots.mm,
title=plot_title,
thickness_scaling=1.2
)
end


#wrangle data
df = query_simulations_for_transition_time_vs_graphmodel_sweep(db_filepath,
                                        game_id=game_id,
                                        memory_length=memory_length,
                                        number_agents=number_agents,
                                        errors=errors,
                                        graphmodel=graphmodel_extra,
                                        startingcondition_id=startingcondition_id,
                                        stoppingcondition_id=stoppingcondition_id,
                                        sample_size=sample_size)
plot_line_number = 1 #this will make the lines unordered***
# for (graph_index, graph) in enumerate(graphmodel_extra)

# function graph_filter(type, β, α, p_in, p_out)
#     type_match = type == graph[:graph_type]
#     β_match = haskey(graph, :β) ? β == graph[:β] : ismissing(β)
#     α_match = haskey(graph, :α) ? α == graph[:α] : ismissing(α)
#     p_in_match = haskey(graph, :p_in) ? p_in == graph[:p_in] : ismissing(p_in)
#     p_out_match = haskey(graph, :p_out) ? p_out == graph[:p_out] : ismissing(p_out)
#     return type_match && β_match && α_match && p_in_match && p_out_match
# end
# filtered_df = filter([:graph_type, :β, :α, :p_in, :p_out] => graph_filter, df)

for (index, error) in enumerate(errors)
filtered_df = filter(:error => err -> err == error, df)
# println(filtered_df)
average_transition_time = Vector{Float64}([])

conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
for (index, sweep_param_val) in enumerate(sweep_param_values)
filtered_df_per_val = filter(sweep_param => val -> val == sweep_param_val, filtered_df)
# println(filtered_df_per_num)
mean_degree = filtered_df_per_val.λ[1] #all should be the same. NOTE: remove this
scaled_periods_elapsed = filtered_df_per_val.periods_elapsed ./ edge_density(number_agents, mean_degree) #NOTE: REMOVE THIS
confidence_interval = confint(bootstrap(mean, scaled_periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple
println(filtered_df_per_val)
println(confidence_interval[1])
push!(average_transition_time, confidence_interval[1]) #first element is the mean
if conf_intervals
push!(confidence_interval_lower, confidence_interval[2])
push!(confidence_interval_upper, confidence_interval[3])
end
end

legend_label = "$(legend_labels_map[index])ϵ=$error"

plot!(sweep_param_values, average_transition_time, markershape = :circle, linewidth=2, label=legend_label, markercolor=colors_map[index], linecolor=colors_map[index])#, linestyle=error_styles_map[error][1])

if conf_intervals
plot!(sweep_param_values, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, label=nothing, fillcolor=colors_map[index])#, fillstyle=error_styles_map[error][2])
end

plot_line_number += 1
end
return sim_plot
end

