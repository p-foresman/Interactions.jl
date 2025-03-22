"""
    Interactions.Registry

Internal module in which various user-created functions are defined. Maintains that the package does not need to reference Main, or any user module.
"""
module Registry
    export graphmodel

    using ..Interactions, Distributed, ParallelDataTransfer
    # module StartingConditions end
    # module StoppingConditions end
    # module GraphModels end
    struct Register
        fn_list::Vector{Expr}

        Register() = new(Vector{Expr}())
    end

    Base.getproperty(::Register, prop::Symbol) = throw("Cannot access $prop") #encapsulation to dissuade users from accessing this
    Base.push!(register::Register, expr::Expr) = push!(getfield(register, :fn_list), expr)
    update_everywhere(register_key::Symbol) = passobj(1, workers(), register_key, from_mod=Registry, to_mod=Interactions.Registry)
    # function define_everywhere(registry::Registry)
    #     for fn in getfield(registry, :fn_list)
    #         @everywhere eval($fn)
    #     end
    # end

    # function define(register::Register)
    #     for fn in getfield(register, :fn_list)
    #         Register.eval(fn)
    #     end
    # end

    # if myid() == 1
    _graphmodel_fn_register = Register()
    # end
    macro graphmodel(fn)
        # @everywhere eval($fn) #NOTE: could do Interactions.eval() to evaluate it into the global scope of Interactions instead of Main
        Registry.eval(fn)
        push!(_graphmodel_fn_register, fn)
        update_everywhere(:_graphmodel_fn_register)
        return nothing
    end

    

    # macro graphmodel(fn)
    #     push!(_graphmodel_fn_registry, fn)
    #     @everywhere eval($fn) #NOTE: could do Interactions.eval() to evaluate it into the global scope of Interactions instead of Main
    #     return nothing
    # end
    # macro graphmodel(fn)
    #     f = Register.eval(fn)
    #     fn_sym = Symbol(nameof(f))
    #     if !(fn_sym in _graphmodel_fn_registry)
    #         push!(_graphmodel_fn_registry, fn_sym) #NOTE: could do Interactions.eval() to evaluate it into the global scope of Interactions instead of Main
    #     end
    #     return nothing
    # end
end