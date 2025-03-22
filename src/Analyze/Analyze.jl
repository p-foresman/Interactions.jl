module Analyze

export
    a,
    transitionTimesBoxPlot

import
    ..Database,
    ..Interactions,
    ..GraphsExt

using
    Plots,
    DataFrames,
    GraphPlot,
    StatsPlots,
    Cairo,
    Fontconfig,
    Statistics,
    Bootstrap,
    ColorSchemes

include("plotting_old.jl") #NOTE: delete eventually
include("plotting.jl")
include("analysis.jl")

end #Analyze