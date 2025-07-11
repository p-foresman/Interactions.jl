# type alias for a function parameter being a specified type OR nothing (used a lot)
const OrNothing{T} = Union{T, Nothing}


# Resets the distributed processes
function resetprocs()
    if nprocs() > 1
        for id in workers()
            rmprocs(id)
        end
    end
end

#takes the product of the lengths of any n vectors to get the n-dimensional volume. (calling this volume but there's probably a name for it)
volume(vec::Vector...) = prod([length(v) for v in vec])

fieldvals(instance::T) where {T} = [getfield(instance, val) for val in fieldnames(T)]


"""
    @suppress f

Suppress any print statements inside a function.
"""
macro suppress(f)
    esc(quote
        so = stdout
        redirect_stdout(devnull)
        $(f)
        redirect_stdout(so)
    end)
end



# function kwargs(m::Method)
#     argnames = ccall(:jl_uncompress_argnames, Vector{Symbol}, (Any,), m.slot_syms)
#     isempty(argnames) && return argnames
#     return argnames[1:m.nargs]
# end

# """
#     collect_kwargs()

# Collects the explicitly typed keyword arguments into a Dict. 
# """
# function collect_kwargs()
#     println(fieldnames(typeof(stacktrace()[2])))
#     method = stacktrace()[2].linfo.def #index 2 will get the previous function called!
#     kws = Base.kwarg_decl(method)
#     function do_it()
#         d = Dict()
#         for kw in kws

#         end
#     end
# end