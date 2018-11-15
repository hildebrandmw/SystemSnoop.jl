
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
[`length`](@ref), [`translate`](@ref), [`startaddress`](@ref), [`stopaddress`](@ref)
"""
struct VMA
    start :: UInt64
    stop :: UInt64
    remainder :: String
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
Base.issubset(a::VMA, b::VMA) = (a.start >= b.start) && (a.stop <= b.stop)


"""
    union(a::VMA, b::VMA) -> VMA

Return a `VMA` that is the union of the regions covered by `a` and `b`. Assumes that `a`
and `b` are [`overlapping`](@ref).
"""
Base.union(a::VMA, b::VMA) = VMA(min(a.start, b.start), max(a.stop, b.stop), a.remainder)


compact(vmas) = (x = copy(vmas); compact!(x); return x)
function compact!(vmas)
    i = 1
    while true
        changed = false
        for j in i+1:length(vmas)
            if overlapping(vmas[i], vmas[j])
                vmas[i] = union(vmas[i], vmas[j])
                deleteat!(vmas, j)
                changed = true
                break
            end
        end
        changed || (i += 1)
        i == length(vmas) && break
    end
    sort!(vmas)
    return nothing
end


# VMA Filters
tautology(args...) = true
heap(vma::VMA) = occursin("heap", vma.remainder)

readable(vma::VMA) = vma.remainder[1] == 'r'
writable(vma::VMA) = vma.remainder[2] == 'w'
executable(vma::VMA) = vma.remainder[3] == 'x'
flagset(vma::VMA) = readable(vma) || writable(vma) || executable(vma)

longerthan(x, n::Integer) = length(x) > n
longerthan(n::Integer) = x -> longerthan(x, n)
