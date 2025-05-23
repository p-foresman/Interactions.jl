function serialize_to_vec(instance::Any)
    buffer = IOBuffer()
    serialize(buffer, instance)
    bin::Vector{UInt8} = take!(buffer)
    close(buffer)
    return bin
end

function deserialize_from_vec(bin::Vector{UInt8})
    buffer = IOBuffer(bin)
    instance = deserialize(buffer)
    close(buffer)
    return instance
end