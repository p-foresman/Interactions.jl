function serialize_to_vec(instance::Any)
    buffer = IOBuffer()
    serialize(buffer, instance)
    bin::Vector{UInt8} = take!(buffer)
    Base.close(buffer)
    return bin
end

function deserialize_from_vec(bin::Vector{UInt8})
    buffer = IOBuffer(bin)
    instance = deserialize(buffer)
    Base.close(buffer)
    return instance
end