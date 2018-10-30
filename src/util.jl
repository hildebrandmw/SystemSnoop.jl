## Helper Functions
############################################################################################

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


"""
    save(file::String, x)

Serialize `x` for `file`.
"""
save(file::String, x) = open(f -> serialize(f, x), file, "w")

"""
    cdf(x) -> Vector

Return the `cdf` of `x`.
"""
function cdf(x) 
    v = x ./ sum(x)
    for i in 2:length(v)
        v[i] = v[i] + v[i-1]
    end
    v
end


## Types
############################################################################################


## VMA ##
# Representation of an OS level VMA. Each process consists of multiple VMAs

"""
Translated Virtual Memory Area (VMA) for a process.

Fields
------
* `start::UInt64` - The starting virtual address for the VMA.
* `stop::UInt64` - The last valid virtual address of the VMA.
* `remainder::String` - The remainder of the entry in `/proc/pid/maps`.

Methods
-------
[`length`](@ref), [`translate`](@ref)
"""
struct VMA
    start :: UInt64
    stop :: UInt64
    remainder :: String
end


"""
    length(vma::VMA) -> Int

Return the size of `vma` in bytes.
"""
length(vma::VMA) = vma.stop - vma.start + 1


"""
    translate(vma::VMA) -> Tuple{Int,Int}

Return tuple of two integers containing the start and stop virtual page indices for `vma`.
"""
translate(vma::VMA; shift = (Int ∘ log2)(PAGESIZE)) = (vma.start, vma.stop) .>> shift

# VMA Filters
tautology(args...) = true
heap(vma::VMA) = occursin("heap", vma.remainder)

readable(vma::VMA) = vma.remainder[1] == 'r'
writable(vma::VMA) = vma.remainder[2] == 'w'
executable(vma::VMA) = vma.remainder[3] == 'x'
flagset(vma::VMA) = readable(vma) || writable(vma) || executable(vma)

longerthan(x, n::Integer) = length(x) > n
longerthan(n::Integer) = x -> longerthan(x, n)




"""
    getvmas!(buffer::Vector{VMA}, pid, [filter])

Fill `buffer` with the Virtual Memory Areas associated with the process with `pid`. Can
optinally supply a filter. 

Filter
------

The filter must be of the form
```julia
f(vma::VMA) -> Bool
```
where `vma` is the parsed VMA region from a line of the process's `maps` file.

For example, if an entry in the `maps` file is
```
0088f000-010fe000 rw-p 00000000 00:00 0
```
then `vma = VMA(0x0088f000,0x010fe000, rw-p 00000000 00:00 0)`
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
            vma = VMA(start, stop, remainder)
            filter(vma) || continue

            push!(buffer, vma)
        end
    end
    return nothing
end


"""
    walkpagemap(f::Function, pid, vmas; [buffer::Vector{UInt64}])

For each [`VMA`](@ref) in iterator `vmas`, store the contents of `/proc/pid/pagemap` into
`buffer` for this `VMA` and call `f(buffer)`.

Note that it is possible for `buffer` to be empty.
"""
function walkpagemap(f::Function, pid, vmas; buffer::Vector{UInt64} = UInt64[])
    # Open the pagemap file. Expect address ranges for the VMAs to be in order.
    open("/proc/$pid/pagemap") do pagemap
        for vma in vmas

            start, stop = translate(vma)
            nwords = stop - start + 1

            # Seek to the start address.
            seek(pagemap, start * sizeof(UInt64))

            if eof(pagemap)
                empty!(buffer)
            else
                resize!(buffer, nwords)
                read!(pagemap, buffer)
            end

            # Call the passed function
            f(buffer)
        end
    end
end
