const Parameters = Dict{Symbol, Float64} #NOTE: could make these <:Real, since some parameters/variables would make more sense as Integers (this might be overcomplicating though)
const Variables = Dict{Symbol, Float64}

"""
    UserFunction

Type that holds information to call a user-defined function.
Used for interaction models, starting conditions, and stopping conditions.
"""
abstract type UserFunction end

struct GraphModel <: UserFunction
    fn_var::Symbol
    parameters::Parameters
    variables::Variables
end

struct StartingCondition <: UserFunction
    fn_var::Symbol
    parameters::Parameters
    variables::Variables
end

struct StoppingCondition <: UserFunction
    fn_var::Symbol
    parameters::Parameters
    variables::Variables
end

fn_var(uf::UserFunction) = getfield(uf, :fn_var)
fn_name(uf::UserFunction) = string(fn_var(uf))
fn(uf::GraphModel) = getfield(Registry.Graphmodels, fn_var(uf))
fn(uf::StartingCondition) = getfield(Registry.StartingConditions, fn_var(uf))
fn(uf::StoppingCondition) = getfield(Registry.StoppingConditions, fn_var(uf))


"""
    parameters(::UserFunction)

Get the parameters of the UserFunction.
"""
parameters(uf::UserFunction) = getfield(uf, :parameters)

"""
    parameters(::UserFunction, key::Symbol)

Get the value of the parameter given.
"""
parameters(uf::UserFunction, key::Symbol) = getindex(parameters(uf), key)

"""
    variables(::UserFunction)

Get the variables of the UserFunction.
"""
variables(uf::UserFunction) = getfield(uf, :variables)

"""
    variables(::UserFunction, key::Symbol)

Get the value of the parameter given.
"""
variables(uf::UserFunction, key::Symbol) = getindex(variables(uf), key)