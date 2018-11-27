############################################################################################

"""
In iterator that returns an infinite amount of `nothing`.
"""
struct Forever end

iterate(Forever, args...) = (nothing, nothing)
IteratorSize(::Forever) = IsInfinite()

#####
##### Pagemap Utilities
#####

"""
Exception indicating that process with `pid` no longer exists.
"""
struct PIDException <: Exception 
    pid::Int64
end

div64(x::Integer) = x >> 6
mod64(x::Integer) = x & 63

"""
    isbitset(x::Integer, b::Integer) -> Bool

Return `true` if bit `b` of `x` is `1`.
"""
isbitset(x::Integer, b) = !iszero(x & (1 << b))

"""
    pfnmask(x::UInt) -> UInt

Return the lower 55 bits of `x`. When applied to a `/proc/pid/pagemap` entry, returns the
physical page number (pfn) of that entry.
"""
pfnmask(x) = x & (~(UInt(0x1ff) << 55))

"""
    inmemory(x::UInt) -> Bool

Return `true` if `x` (interpreted as an entry in Linux `/pagemap`) if located in memory.
"""
inmemory(x) = isbitset(x, 63)

"""
    isactive(x::Integer, buffer::Vector{UInt64}) -> Bool

Return `true` if bit `x` of `buffer` is set, intrerpreting `buffer` as a contiguous chunk 
of memory.
"""
@inline function isactive(x::Integer, buffer::Vector{UInt64})
    # Filter out frames that are not active in memory.
    if inmemory(x)
        # Get the physical frame number from the entry. Check the buffer to see if the
        # frame is active or not.
        framenumber =  pfnmask(x)
        chunk = buffer[div64(framenumber) + 1]
        return !isbitset(chunk, mod64(framenumber))
    end
    return false
end

#####
##### OS Utilities
#####

"""
    pause(pid)

Pause process with `pid`. If process does not exist, throw a [`PIDException`](@ref).
"""
function pause(pid) 
    try
        run(`kill -STOP $pid`)
    catch error
        isa(error, ErrorException) ? throw(PIDException(pid)) : rethrow(error)
    end
    return nothing
end

"""
    resume(pid)

Resume process with `pid`. If process does not exist, throw a [`PIDException`](@ref)
"""
function resume(pid)  
    try
        run(`kill -CONT $pid`)
    catch error
        isa(error, ErrorException) ? throw(PIDException(pid)) : rethrow(error)
    end
    return nothing
end

