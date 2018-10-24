## Helper Functions
############################################################################################


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
    isactive(x::Integer, buffer::Vector{UInt64})

TODO
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

Pause process with `pid`.
"""
pause(pid) = run(`kill -STOP $pid`)


"""
    resume(pid)

Resume process with `pid`.
"""
resume(pid) = run(`kill -CONT $pid`)


## Types
############################################################################################


## VMA ##
# Representation of an OS level VMA. Each process consists of multiple VMAs
struct VMA
    start :: UInt64
    stop :: UInt64
end

length(vma::VMA) = vma.stop - vma.start
function translate(vma::VMA; entrysize = PAGEMAP_ENTRY_SIZE_BYTES, shift = (Int ∘ log2)(PAGESIZE))
    start = entrysize * vma.start >> shift
    stop = entrysize * vma.stop >> shift
    return start, stop
end

# VMA Filters
tautology(args...) = true
heap_filter(::VMA, remainder) = occursin("heap", remainder)


"""
    getvmas!(buffer::Vector{VMA}, pid, [filter])

Fill `buffer` with the Virtual Memory Areas associated with the process with `pid`. Can
optinally supply a filter. 

Filter
------

The filter must be of the form
```julia
f(vma::VMA, str::String) -> Bool
```
where `vma` is the parsed VMA region from a line of the process's `maps` file and `str` is
the remainder of the line from the `maps` file. 

For example, if an entry in the `maps` file is
```
0088f000-010fe000 rw-p 00000000 00:00 0
```
then `vma = VMA(0x0088f000,0x010fe000)` and `str = "rw-p 00000000 00:00 0"`.
"""
function getvmas!(buffer::Vector{VMA}, pid, filter = tautology)
    # maps/ entries look like this
    #
    # 0088f000-010fe000 rw-p 00000000 00:00 0
    #
    # Where the first pair of numbers is the range of addresses for this unit.
    # The strategy here is to find up to the first "-", parse as an int, then parse to the
    # next " "
    empty!(buffer)
    open("/proc/$pid/maps") do f
        while !eof(f)
            start = parse(UInt, readuntil(f, '-'); base = 16)
            stop = parse(UInt, readuntil(f, ' '); base = 16) - one(UInt)

            # Wrap to the next line
            remainder = readuntil(f, '\n')
            vma = VMA(start, stop)
            filter(vma, remainder) || continue

            push!(buffer, VMA(start, stop))
        end
    end
    return nothing
end


"""
    walkpagemap(f::Function, pid, vmas; [buffer::Vector{UInt8}])


"""
function walkpagemap(f::Function, pid, vmas; buffer::Vector{UInt8} = UInt8[])
    # Open the pagemap file. Expect address ranges for the VMAs to be in order.
    open("/proc/$pid/pagemap") do pagemap
        for vma in vmas

            start, stop = translate(vma)
            nbytes = stop - start
            # Seek to the start address.
            seek(pagemap, start)

            empty!(buffer)
            readbytes!(pagemap, buffer, nbytes)
            region = reinterpret(UInt64, buffer)

            # Call the passed function
            f(region)
        end
    end
end
