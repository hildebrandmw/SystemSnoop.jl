"""
Compact representation of data of type `T` that is both sorted and usually occurs in
contiguous ranges. For example, since groups of virtual memory pages are usually accessed
together, a `SortedRangeVector` can encode those more compactly than a normal vector.

Fields
------

* `ranges :: Vector{UnitRange{T}` - The elements of the `SortedRangeVector`, compacted into
    contiguous ranges.

Constructor
-----------

    SortedRangeVector{T}() -> SortedRangeVector{T}

Construct a empty `SortedRangeVector` with element type `T`.
"""
struct SortedRangeVector{T} <: AbstractVector{UnitRange{T}}
    ranges::Vector{UnitRange{T}}
end
SortedRangeVector{T}() where {T} = SortedRangeVector{T}(UnitRange{T}[])

# Convenience methods
length(R::SortedRangeVector) = length(R.ranges)
iterate(R::SortedRangeVector, args...) = iterate(R.ranges, args...)
size(R::SortedRangeVector) = (length(R),)

sumall(R::SortedRangeVector{T}) where T = length(R) > 0 ? sum(length, R.ranges) : zero(T)


# Fordwarding methods
getindex(R::SortedRangeVector, inds...) = getindex(R.ranges, inds...)

searchsortedfirst(R::SortedRangeVector{T}, x::T; lt = (x,y) -> (last(x) < y), kw...) where T = 
    searchsortedfirst(R.ranges, x; lt = lt, kw...)


"""
    lastelement(R::SortedRangeVector{T}) -> T

Return the last element of the last range of `R`.
"""
lastelement(R::SortedRangeVector) = (last ∘ last)(R.ranges)

"""
    push!(R::SortedRangeVector{T}, x::T)

Add `x` to the end of `R`, merging `x` into the final range if appropriate.
"""
function push!(R::SortedRangeVector{T}, x::T) where T
    # Check to see if `x` can be appended to the last element of `R`.
    if !isempty(R.ranges) && (x - lastelement(R)) == one(T)
        R.ranges[end] = (first ∘ last)(R.ranges):x
    else
        push!(R.ranges, x:x)
    end
    nothing
end

function push!(A::SortedRangeVector{T}, x::UnitRange{T}) where T
    if !isempty(A) && first(x) <= lastelement(A) + one(T)
        A.ranges[end] = first(last(A)):last(x)
    else
        push!(A.ranges, x)
    end
end

"""
    in(x, R::SortedRangeVector) -> Bool

Perform an efficient search of `R` for item `x`, assuming the ranges in `R` are sorted and
non-overlapping.
"""
function in(x, R::SortedRangeVector)
    # Find the first range that can possibly contain "x". Since ranges are expected to be
    # sorted, this is the ONLY range that can container "x".
    index = searchsortedfirst(R, x)

    # Make sure index is inbounds (if no range is found, index will be out of bounds), then
    # check if "x" is actually in the range.
    return (index <= length(R)) && in(x, R[index])
end


function union(A::SortedRangeVector{T}, B::SortedRangeVector{T}) where T
    U = SortedRangeVector{T}()

    ia = iterate(A)
    ib = iterate(B)

    local X, ix

    while true
        # Check iterators
        ia === nothing && (X = B; ix = ib; break)
        ib === nothing && (X = A; ix = ia; break)

        # Unpack iterators
        a, sa = ia
        b, sb = ib

        # Check which one is lower
        if first(a) <= first(b) 
            push!(U, a)
            ia = iterate(A, sa)
        else
            push!(U, b)
            ib = iterate(B, sb)
        end
    end

    # Add the rest to the result vector.
    while true
        ix === nothing && break 
        x, sx = ix

        mergepush!(U, x)
        ix = iterate(X, sx)
    end

    return U
end

