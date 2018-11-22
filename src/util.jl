## Helper Functions
############################################################################################
#
struct PIDException <: Exception end

"""
In iterator that returns an infinite amount of `nothing`.
"""
struct Forever end

iterate(Forever, args...) = (nothing, nothing)
IteratorSize(::Forever) = IsInfinite()


"""
    increment!(d::AbstractDict, k, v)

Increment `d[k]` by `v`. If `d[k]` does not exist, initialize it to `v`.
"""
increment!(d::AbstractDict, k, v) = haskey(d, k) ? (d[k] += v) : (d[k] = v)


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


div64(x::Integer) = x >> 6
mod64(x::Integer) = x & 63

"""
    isbitset(x::Integer, b::Integer) -> Bool

Return `true` if bit `b` of `x` is `1`.
"""
isbitset(x::Integer, b) = !iszero(x & (1 << b))


"""
    pause(pid)

Pause process with `pid`. If process does not exist, throw a [`PIDException`](@ref).
"""
function pause(pid) 
    try
        run(`kill -STOP $pid`)
    catch error
        isa(error, ErrorException) ? throw(PIDException()) : rethrow(error)
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
        isa(error, ErrorException) ? throw(PIDException()) : rethrow(error)
    end
    return nothing
end

save(file::String, x) = open(f -> serialize(f, x), file, write = true)
load(file::String) = open(deserialize, file)


"""
    cdf(x) -> Vector

Return the `cdf` of `x`.
"""
function cdf(x) 
    v = x ./ sum(x)
    for i in 2:length(v)
        v[i] = v[i] + v[i-1]
    end
    return v
end

"""
    walkpagemap(f::Function, pid, vmas; [buffer::Vector{UInt64}])

For each [`VMA`](@ref) in iterator `vmas`, store the contents of `/proc/pid/pagemap` into
`buffer` for this `VMA` and call `f(buffer)`.

Note that it is possible for `buffer` to be empty.
"""
function walkpagemap(f::Function, pid, vmas; buffer::Vector{UInt64} = UInt64[])
    # Open the pagemap file. Expect address ranges for the VMAs to be in order.
    try 
        open("/proc/$pid/pagemap") do pagemap
            for vma in vmas

                # Seek to the start address.
                seek(pagemap, vma.start * sizeof(UInt64))
                if eof(pagemap)
                    empty!(buffer)
                else
                    resize!(buffer, length(vma))
                    read!(pagemap, buffer)
                end

                # Call the passed function
                f(buffer)
            end
        end
    catch error
        # Check the error, if it's a "file not found", throw a PID error to excape.
        # otherwise, rethrow the error
        if isa(error, SystemError) && error.errnum == 2
            throw(PIDException())
        else
            rethrow(error)
        end
    end
    return nothing
end
