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