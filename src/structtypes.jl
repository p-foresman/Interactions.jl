# This file contains all global StructType assignments required for JSON3 functionality

using StructTypes


################################## Agent Type #######################################
StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable()


################################ Parameters Type #####################################
StructTypes.StructType(::Type{Parameters}) = StructTypes.Struct()


####################### Xoshiro random number generator type ########################
#Needed to read and write the state of the Xoshiro RNG with JSON3 package
StructTypes.StructType(::Type{Random.Xoshiro}) = StructTypes.Mutable()


################################## Game Type ########################################
#Enter any new payoff matrix sizes here in the format: StructTypes.StructType(::Type{Game{rows, cols, length}}) = StructTypes.Struct()
StructTypes.StructType(::Type{Game{3, 3, 9}}) = StructTypes.Struct() #NOTE: fix this (user should not have to enter these)