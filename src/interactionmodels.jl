#NOTE: fix documentation!
"""
    InteractionModel

An abstract type representing all interaction parameter types.
"""
abstract type InteractionModel end

"""
    GraphModel

An abstract type representing the class of graph interaction parameters.
"""
struct GraphModel <: InteractionModel
    fn_name::String
    params::NamedTuple #(param=arg,) notation
    param_types::Tuple #might not need
    kwargs::Dict

    function GraphModel(fn_name::String, args::NamedTuple, kwargs::Dict{Symbol, Any})
        # @assert #make sure fn_name is in Registry
        @assert isdefined(Registry, Symbol(fn_name)) "'fn_name' provided does not correlate to a defined function in the Registry. Must use @graphmodel macro before function to register it" #NOTE: change to Registry
        # @assert all(i -> isa(i, Real), values(args)) "All args must be <:Real" #NOTE: should we require this?
        f = getfield(Registry, Symbol(fn_name)) #get the function
        arg_types = map(arg->typeof(arg), collect(args))
        m = which(f, (Parameters, arg_types...)) #get the method associated with the arg types provided. This will error if the arguments provided don't match the type specifications for the Function
        param_types = Base.arg_decl_parts(m)[2][3:end] #first index is function name, second should be Parameters type
        arg_names = keys(args)
        for i in eachindex(param_types) #ensure the orders of arguments are right. If these are right, args is sufficiently validated since type validation was completed previously
            @assert Symbol(param_types[i][1]) == arg_names[i] "arguments provided must be in the order of the function parameters"
        end
        
        @assert Base.return_types(f, (Parameters, arg_types...))[1] <: GraphsExt.Graphs.SimpleGraph "the fn provided must return a Graphs.SimpleGraph"

        return new(fn_name, args, Tuple(arg_types), kwargs) #(; zip(params , ordered_args)...)
    end
    GraphModel(fn_name::String; kwargs::Dict{Symbol, Any}=Dict{Symbol, Any}(), args...) = GraphModel(fn_name, NamedTuple(args), kwargs)
end

    
fn_name(graphmodel::GraphModel) = getfield(graphmodel, :fn_name)
fn(graphmodel::GraphModel) = getfield(Registry, Symbol(fn_name(graphmodel)))
params(graphmodel::GraphModel) = getfield(graphmodel, :params)
args(graphmodel::GraphModel) = values(params(graphmodel))
kwargs(graphmodel::GraphModel) = getfield(graphmodel, :kwargs)

# const _graphmodel_fn_registry = Vector{Expr}()

# """
#     @stoppingcondition fn

# A macro used to register user stopping conditions to be used in  This MUST precede any stopping conditions used in a user's simulations.
# """
# macro graphmodel(fn)
#     push!(_graphmodel_fn_registry, fn)
#     @everywhere eval($fn) #NOTE: could do eval() to evaluate it into the global scope of Interactions instead of Registry
#     return nothing
# end

"""
    displayname(graphmodel::GraphModel)

Get the string used for displaying a GraphModel instance.
"""
displayname(graphmodel::GraphModel) = "$(fn_name(graphmodel))$(isempty(params(graphmodel)) ? "" : " $(params(graphmodel))")"
Base.show(graphmodel::GraphModel) = println(displayname(graphmodel))

function generate_graph(graphmodel::GraphModel, parameters::Parameters)::GraphsExt.Graphs.SimpleGraph
    graph::GraphsExt.Graphs.SimpleGraph = fn(graphmodel)(parameters, args(graphmodel)...; kwargs(graphmodel)...)
    if GraphsExt.ne(graph) == 0 #NOTE: we aren't considering graphs with no edges (obviously). Does it even make sense to consider graphs with more than one component?
        return generate_graph(graphmodel, parameters)
    end
    return graph
end