#This file contains all global StructType assignments required for JSON3 functionality

#If a new payoff matrix size is used in a game (e.g. new Game{S1, S2}() is initialized), a new StructType must be added to this list 

using StructTypes


################################## Agent Type #######################################
StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable()



################################ Parameters Type #####################################
StructTypes.StructType(::Type{Parameters}) = StructTypes.Struct()


############################## GraphParams Types ####################################
#This StructTypes hierarchy is required to reproduce any given subtype from the abstract type input
# StructTypes.StructType(::Type{GraphModel}) = StructTypes.AbstractType()
# StructTypes.StructType(::Type{CompleteModel}) = StructTypes.Struct()
# StructTypes.StructType(::Type{ErdosRenyiModel}) = StructTypes.Struct()
# StructTypes.StructType(::Type{SmallWorldModel}) = StructTypes.Struct()
# StructTypes.StructType(::Type{ScaleFreeModel}) = StructTypes.Struct()
# StructTypes.StructType(::Type{StochasticBlockModel}) = StructTypes.Struct()
# StructTypes.subtypekey(::Type{GraphModel}) = :type
# StructTypes.subtypes(::Type{GraphModel}) = (CompleteModel=CompleteModel, ErdosRenyiModel=ErdosRenyiModel, SmallWorldModel=SmallWorldModel, ScaleFreeModel=ScaleFreeModel, StochasticBlockModel=StochasticBlockModel)


############################# StartingCondition Types ###############################
# StructTypes.StructType(::Type{StartingCondition}) = StructTypes.AbstractType()
# StructTypes.StructType(::Type{FractiousState}) = StructTypes.Struct()
# StructTypes.StructType(::Type{EquityState}) = StructTypes.Struct()
# StructTypes.StructType(::Type{RandomState}) = StructTypes.Struct()
# StructTypes.subtypekey(::Type{StartingCondition}) = :type
# StructTypes.subtypes(::Type{StartingCondition}) = (FractiousState=FractiousState, EquityState=EquityState, RandomState=RandomState)


############################# StoppingCondition Types ###############################
# StructTypes.StructType(::Type{StoppingCondition}) = StructTypes.AbstractType()
# StructTypes.StructType(::Type{EquityPsychological}) = StructTypes.Mutable()
# StructTypes.StructType(::Type{EquityBehavioral}) = StructTypes.Mutable()
# StructTypes.StructType(::Type{PeriodCutoff}) = StructTypes.Struct()
# StructTypes.subtypekey(::Type{StoppingCondition}) = :type
# StructTypes.subtypes(::Type{StoppingCondition}) = (EquityPsychological=EquityPsychological, EquityBehavioral=EquityBehavioral, PeriodCutoff=PeriodCutoff)



####################### Xoshiro random number generator type ########################
#Needed to read and write the state of the Xoshiro RNG with JSON3 package
StructTypes.StructType(::Type{Random.Xoshiro}) = StructTypes.Mutable()



################################## Game Type ########################################
#Enter any new payoff matrix sizes here in the format: StructTypes.StructType(::Type{Game{rows, cols, length}}) = StructTypes.Struct()
StructTypes.StructType(::Type{Game{3, 3, 9}}) = StructTypes.Struct()