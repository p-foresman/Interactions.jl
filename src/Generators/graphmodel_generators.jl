# abstract type GraphModelGenerator <: Generator end

struct GraphModelGenerator <: Generator
    fn_name::String
    params::NamedTuple #(param=[args...],) notation
    kwargs::Dict{Symbol, Any} #NOTE: need to figure out how to implement this!
    size::Int

    function GraphModelGenerator(fn_name::String, args::NamedTuple, kwargs::Dict{Symbol, Any}=Dict{Symbol, Any}())
        @assert isdefined(Registry.GraphModels, Symbol(fn_name)) "'fn_name' provided does not correlate to a defined function in the Registry. Must use @graphmodel macro before function to register it"
        f = getfield(Registry.GraphModels, Symbol(fn_name)) #get the function
        arg_types = Vector{Type}()
        for arg in args
            type = typeof(arg)
            if type <: Vector
                type = typeof(first(arg))
                all(a->typeof(a)==type, arg)
            end
            push!(arg_types, type)
        end
        m = which(f, (Parameters, arg_types...)) #get the method associated with the arg types provided. This will error if the arguments provided don't match the type specifications for the Function
        param_types = Base.arg_decl_parts(m)[2][3:end] #first index is function name, second should be Parameters type
        arg_names = keys(args)
        for i in eachindex(param_types) #ensure the orders of arguments are right. If these are right, args is sufficiently validated since type validation was completed previously
            @assert Symbol(param_types[i][1]) == arg_names[i] "arguments provided must be in the order of the function parameters"
        end
        @assert Base.return_types(f, (Parameters, arg_types...))[1] <: Graphs.SimpleGraph "the fn provided must return a Graphs.SimpleGraph"
        #@assert all(i -> isa(i, Real) || isa(i, Vector{<:Real}), values(params)) "All params must Union{Real, Vector{<:Real}}"
        k = keys(args)
        v = map(x->isa(x, Vector) ? x : [x], collect(args))
        return new(fn_name, NamedTuple{k}(v), kwargs, Interactions.volume(v...)) #convert back into NamedTuple (where all values are now Vector{<:Real})
    end
    GraphModelGenerator(fn_name::String; kwargs::Dict{Symbol, Any}=Dict{Symbol, Any}(), args...) = GraphModelGenerator(fn_name, NamedTuple(args), kwargs)
end

function generate_model(graphmodel_generator::GraphModelGenerator, index::Integer)
    k = keys(graphmodel_generator.params)
    v = first(Iterators.drop(Iterators.product(values(graphmodel_generator.params)...), index - 1))
    return GraphModel(graphmodel_generator.fn_name, NamedTuple{k}(v), graphmodel_generator.kwargs)
end

#NOTE: make a GraphModelGeneratorSet

# Base.size(graphmodel_generator::GraphModelGenerator) = getfield(graphmodel_generator, :size)

#get_params(vec::Vector...; index::Integer) = first(Iterators.drop(Iterators.product(vec...), index - 1))