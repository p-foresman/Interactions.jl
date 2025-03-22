"""
    Interactions.Registry

Internal module in which various user-created functions are defined. Maintains that the package does not need to reference Main, or any user module.
"""
module Registry

export @graphmodel, @startingcondition, @stoppingcondition
using ..Interactions, Distributed, ParallelDataTransfer, Graphs

"""
    Register

Type that stores unevaluated function expressions for various user-defined functions.
"""
struct Register
    fn_list::Vector{Expr}

    Register() = new(Vector{Expr}())
end

Base.getproperty(::Register, prop::Symbol) = throw("Cannot access $prop") #encapsulation to dissuade users from accessing this
Base.push!(register::Register, expr::Expr) = push!(getfield(register, :fn_list), expr)
Base.length(register::Register) = length(getfield(register, :fn_list))
Base.getindex(register::Register, index::Integer) = getindex(getfield(register, :fn_list), index)

function Base.iterate(register::Register, state=1)
    if state > length(register)
        return nothing
    else
        return (register[state], state + 1)
    end    
end

function register_all(register_key::Symbol)
    for fn_expr in getfield(Registry, register_key)
        Registry.eval(fn_expr)
    end
end

function update_everywhere(register_key::Symbol)
    passobj(1, workers(), register_key, from_mod=Registry, to_mod=Interactions.Registry)
    # for worker in workers()
    #     @spawnat worker register_all(register_key)
    # end
    for worker in workers()
        remote_do(()->Interactions.Registry.register_all(register_key), worker) #doesnt work. Is it copying the function and transfering it over? 
    end
end



# module GraphModelRegistry
    export @graphmodel
    _graphmodel_fn_register = Register()

    """
        @graphmodel

    Used to register a function as a graphmodel.
    """
    macro graphmodel(fn_expr)
        fn = Registry.eval(fn_expr)
        println(fn)
        if !isa(fn, Function)
            #NOTE: delete function!
            throw(AssertionError("Missuse of @graphmodel. Must pass a Function as an argument"))
        end
        push!(_graphmodel_fn_register, fn_expr)
        update_everywhere(:_graphmodel_fn_register)
        return nothing
    end
# end
# import .GraphModelRegistry: @gra



###### Starting Condition Register #######
_starting_condition_fn_register = Register()

"""
    @startingcondition

Used to register a function as a starting condition.
"""
macro startingcondition(fn_expr)
    Registry.eval(fn_expr)
    push!(_starting_condition_fn_register, fn_expr)
    update_everywhere(:_starting_condition_fn_register)
    return nothing
end


###### Stopping Condition Register #######
_stopping_condition_fn_register = Register()

"""
    @stoppingcondition

Used to register a function as a stopping condition.
"""
macro stoppingcondition(fn_expr)
    Registry.eval(fn_expr)
    push!(_stopping_condition_fn_register, fn_expr)
    update_everywhere(:_stopping_condition_fn_register)
    return nothing
end
    

# function _assert_registries() #not sure what this was
#     @assert !isempty(_starting_condition_registry) "Must define at least one starting condition function with the @startingcondition macro"
#     @assert !isempty(_stopping_condition_registry) "Must define at least one stopping condition function with the @stoppingcondition macro"
#     return nothing
# end

end