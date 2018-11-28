
## Types
###########################################################################################
#

## VMA ##
# Representation of an OS level VMA. Each process consists of multiple VMAs

"""
Translated Virtual Memory Area (VMA) for a process.

Fields
------
* `start::UInt64` - The starting virtual page number for the VMA.
* `stop::UInt64` - The last valid virtual page number for the VMA.
* `remainder::String` - The remainder of the entry in `/proc/pid/maps`.

Methods
-------
[`length`](@ref), [`startaddress`](@ref), [`stopaddress`](@ref)
"""
struct VMA
    start :: UInt64
    stop :: UInt64
    remainder :: String

    # Innser constructor - auto convert and fill in remainder
    VMA(start::Integer, stop::Integer, remainder = "") = new(UInt64(start), UInt64(stop), remainder)
end

Base.isless(a::VMA, b::VMA) = a.stop < b.start


"""
    startaddress(vma::VMA) -> UInt

Return the first virtual addresses assigned to `vma`.
"""
startaddress(vma::VMA) = PAGESIZE * vma.start


"""
    stopaddres(vma::VMA) -> UInt

Return the last virtual addresses assigned to `vma`.
"""
stopaddress(vma::VMA) = PAGESIZE * vma.stop


"""
    length(vma::VMA) -> Int

Return the size of `vma` in number of pages.
"""
length(vma::VMA) = Int(vma.stop - vma.start + 1)


"""
    overlapping(a::VMA, b::VMA) -> Bool

Return `true` if VMA regions `a` and `b` overlap.
"""
overlapping(a::VMA, b::VMA) = !((a.stop < b.start) || (b.stop < a.start))


"""
    issubset(a::VMA, b::VMA) -> Bool

Return `true` if VMA region `a` is a subset of `b`.
"""
issubset(a::VMA, b::VMA) = (a.start >= b.start) && (a.stop <= b.stop)


"""
    union(a::VMA, b::VMA) -> VMA

Return a `VMA` that is the union of the regions covered by `a` and `b`. Assumes that `a`
and `b` are [`overlapping`](@ref).
"""
union(a::VMA, b::VMA) = VMA(min(a.start, b.start), max(a.stop, b.stop), a.remainder)


"""
    compact(vmas::Vector{VMA}) -> Vector{VMA}

Given an unsorted collection `vmas`, return the smallest collection ``V`` such that

* For any ``u \\in vmas``, ``u \\subset v`` for some ``v \\in V``.
* All elements of ``V`` are disjoint.
* ``V`` is sorted by starting address.
"""
compact(vmas) = (x = copy(vmas); compact!(x); return x)
function compact!(vmas)
    # Base index - need to compare the item at this index to every other item in the
    # set
    i = 1

    # Keep iterating until all possible mergings have been completed.
    while true
        changed = false

        # Look at all items above the base item
        for j in i+1:length(vmas)
            if overlapping(vmas[i], vmas[j])
                vmas[i] = union(vmas[i], vmas[j])
                deleteat!(vmas, j)
                changed = true
                break
            end
        end

        # If no items above overlap, the next item in the collection becomes the base
        # item.
        changed || (i += 1)
        i == length(vmas) && break
    end
    sort!(vmas)
    return nothing
end


# VMA Filters
tautology(args...) = true

"Return `true` if `vma` is for the heap."
heap(vma::VMA) = occursin("heap", vma.remainder)

"Return `true` if `vma` is readable."
readable(vma::VMA) = vma.remainder[1] == 'r'

"Return `true` if `vma` is writable."
writable(vma::VMA) = vma.remainder[2] == 'w'

"Return `true` if `vma` is executable."
executable(vma::VMA) = vma.remainder[3] == 'x'

"Return `true` if `vma` is either readable, writeable, or executable"
flagset(vma::VMA) = readable(vma) || writable(vma) || executable(vma)

"""
    longerthan(x, n) -> Bool

Return `true` if `length(x) > n`

    longerthan(n) -> Function

Return a function `x -> longerthan(x, n)`
"""
longerthan(x, n::Integer) = length(x) > n
longerthan(n::Integer) = x -> longerthan(x, n)


"""
    getvmas!(buffer::Vector{VMA}, pid, [filter])

Fill `buffer` with the Virtual Memory Areas associated with the process with `pid`. Can
optinally supply a filter. VMAs in `buffer` will be sorted by virtual address.

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
    #
    # Ordering of VMAs comes from the ordering from /proc/pid/maps
    empty!(buffer)
    try
        open("/proc/$pid/maps") do f
            while !eof(f)
                start = parse(UInt, readuntil(f, '-'); base = 16) >> PAGESHIFT
                stop = (parse(UInt, readuntil(f, ' '); base = 16) - one(UInt)) >> PAGESHIFT

                # Wrap to the next line
                remainder = readuntil(f, '\n')
                vma = VMA(start, stop, remainder)
                filter(vma) || continue

                push!(buffer, vma)
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
