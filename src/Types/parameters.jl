const UserVariables = Dict{Symbol, Any}

"""
    Parameters

Type to define and store simulation parameters.
"""
struct Parameters #NOTE: allow user to define the matches_per_period (default 1?)
    number_agents::Int #switch to 'population'
    memory_length::Int
    error::Float64
    # matches_per_period::Function #allow users to define their own matches per period as a function of other parameters?
    starting_condition_fn_name::String
    stopping_condition_fn_name::String
    user_variables::UserVariables #NOTE: should starting_condition_variables and stopping_condition_variables be separated? (maybe not, it's on the user to manage these)
    # random_seed::Int #probably don't need a random seed in every Parameters struct?


    function Parameters(number_agents::Int, memory_length::Int, error::Float64, starting_condition_fn_name::String, stopping_condition_fn_name::String; user_variables::UserVariables=UserVariables())
        @assert number_agents >= 2 "'population' must be >= 2"
        @assert memory_length >= 1 "'memory_length' must be positive"
        @assert 0.0 <= error <= 1.0 "'error' must be between 0.0 and 1.0"
        @assert isdefined(Registry.StartingConditions, Symbol(starting_condition_fn_name)) "'starting_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @startingcondition macro before function to register it"
        @assert isdefined(Registry.StoppingConditions, Symbol(stopping_condition_fn_name)) "'stopping_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @stoppingcondition macro before function to register it"
        return new(number_agents, memory_length, error, starting_condition_fn_name, stopping_condition_fn_name, user_variables)
    end
    function Parameters()
        return new()
    end
    function Parameters(number_agents::Int, memory_length::Int, error::Float64, starting_condition_fn_name::String, stopping_condition_fn_name::String, user_variables::UserVariables)
        @assert number_agents >= 2 "'population' must be >= 2"
        @assert memory_length >= 1 "'memory_length' must be positive"
        @assert 0.0 <= error <= 1.0 "'error' must be between 0.0 and 1.0"
        @assert isdefined(Registry.StartingConditions, Symbol(starting_condition_fn_name)) "'starting_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @startingcondition macro before function to register it"
        @assert isdefined(Registry.StoppingConditions, Symbol(stopping_condition_fn_name)) "'stopping_condition_fn_name' provided does not correlate to a defined function in the Registry. Must use @stoppingcondition macro before function to register it"
        return new(number_agents, memory_length, error, starting_condition_fn_name, stopping_condition_fn_name, user_variables)
    end
end


##########################################
# Parameters Accessors
##########################################

"""
    number_agents(params::Parameters)

Get the population size simulation parameter N.
"""
number_agents(params::Parameters) = getfield(params, :number_agents)

"""
    memory_length(params::Parameters)

Get the memory length simulation parameter m.
"""
memory_length(params::Parameters) = getfield(params, :memory_length)

"""
    error_rate(params::Parameters)

Get the error rate simulation parameter ϵ.
"""
error_rate(params::Parameters) = getfield(params, :error)

# """
#     matches_per_period(params::Parameters)

# Get the number of matches per period for the simulation.
# """
# matches_per_period(params::Parameters) = getfield(params, :matches_per_period)

# """
#     random_seed(params::Parameters)

# Get the random seed for the simulation.
# """
# random_seed(params::Parameters) = getfield(params, :random_seed)





"""
    starting_condition_fn_name(params::Parameters)

Get the 'starting_condition_fn_name' Parameters field.
"""
starting_condition_fn_name(params::Parameters) = getfield(params, :starting_condition_fn_name)

"""
    starting_condition_fn(params::Parameters)

Get the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_name' Parameters field.
"""
starting_condition_fn(params::Parameters) = getfield(Registry.StartingConditions, Symbol(starting_condition_fn_name(params)))



"""
    stopping_condition_fn_name(params::Parameters)

Get the 'stopping_condition_fn_name' Parameters field.
"""
stopping_condition_fn_name(params::Parameters) = getfield(params, :stopping_condition_fn_name)

"""
    stopping_condition_fn(params::Parameters)

Get the user-defined stopping condition function which correlates to the String stored in the 'stopping_condition_fn' Parameters field.
"""
stopping_condition_fn(params::Parameters) = getfield(Registry.StoppingConditions, Symbol(stopping_condition_fn_name(params)))




"""
    user_variables(params::Parameters)

Get the extra user-defined SimParam variables. Note: these should denote default values and should only be updated in State!
"""
user_variables(params::Parameters) = getfield(params, :user_variables)

# setfield!(::Parameters, :user_variables, ::Any) = raise Exception() #dont want user to be able to change this


"""
    displayname(params::Parameters)

Get the string used for displaying a Parameters instance.
"""
displayname(params::Parameters) = "N=$(number_agents(params)) m=$(memory_length(params)) e=$(error_rate(params)) starting=$(starting_condition_fn_name(params)) stopping=$(stopping_condition_fn_name(params))"

Base.show(params::Parameters) = println(displayname(params))




##########################################
# Parameters Extra Constructors
##########################################

"""
    construct_params_list(;number_agents_list::Vector{<:Integer}, memory_length_list::Vector{<:Integer}, error_list::Vector{Float64}, tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int} = nothing)

Construct a list of Parameters instances with various parameter combinations.
"""
function construct_params_list(;number_agents_list::Vector{Int}, memory_length_list::Vector{Int}, error_list::Vector{Float64}, random_seed::Union{Nothing, Int} = nothing)
    params_list = Vector{Parameters}([])
    for number_agents in number_agents_list
        for memory_length in memory_length_list
            for error in error_list
                new_params_set = Parameters(number_agents, memory_length, error, random_seed=random_seed)
                push!(params_list, new_params_set)
            end
        end
    end
    return params_list
end