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

Methods
-------
* [`sumall`](@ref)
* [`lastelement`](@ref)
* [`push!`](@ref)
* [`in`](@ref)
* [`union`](@ref)
"""
struct SortedRangeVector{T} <: AbstractVector{UnitRange{T}}
    ranges::Vector{UnitRange{T}}
end
SortedRangeVector{T}() where {T} = SortedRangeVector{T}(UnitRange{T}[])

# Convenience methods
length(V::SortedRangeVector) = length(V.ranges)
iterate(V::SortedRangeVector, args...) = iterate(V.ranges, args...)
size(V::SortedRangeVector) = (length(V),)

"""
    sumall(V::SortedRangeVector)

Return the sum of lengths of each element of `V`.
"""
sumall(V::SortedRangeVector{T}) where T = length(V) > 0 ? Int(sum(length, V.ranges)) : 0


# Fordwarding methods
getindex(V::SortedRangeVector, inds...) = getindex(V.ranges, inds...)

searchsortedfirst(V::SortedRangeVector{T}, x::T; lt = (x,y) -> (last(x) < y), kw...) where T = 
    searchsortedfirst(V.ranges, x; lt = lt, kw...)


"""
    lastelement(V::SortedRangeVector{T}) -> T

Return the last element of the last range of `V`.
"""
lastelement(V::SortedRangeVector) = (last ∘ last)(V.ranges)

#####
##### Efficient Specializations
#####

"""
    push!(V::SortedRangeVector{T}, x::T) where {T}

Add `x` to the end of `V`, merging `x` into the final range if appropriate.

    push!(V::SortedRangeVector{T}, x::UnitRange{T}) where {T}

Merge `x` with the final range in `V` if they overlap. Otherwise, append `x` to the
end of `V`.

**NOTE**: Assumes that `first(x) >= first(last(V))` 
"""
function push!(V::SortedRangeVector{T}, x::T) where {T}
    # Check to see if `x` can be appended to the last element of `V`.
    if !isempty(V.ranges) && (x - lastelement(V)) == one(T)
        V.ranges[end] = (first ∘ last)(V.ranges):x
    else
        push!(V.ranges, x:x)
    end
    nothing
end

function push!(V::SortedRangeVector{T}, x::UnitRange{T}) where {T}
    if !isempty(V) && first(x) <= lastelement(V) + one(T)
        @inbounds V.ranges[end] = first(last(V)):max(last(x), lastelement(V))
    else
        push!(V.ranges, x)
    end
end

"""
    in(x, V::SortedRangeVector) -> Bool

Perfor an efficient search in `V` for `x`.
"""
function in(x, V::SortedRangeVector)
    # Find the first range that can possibly contain "x". Since ranges are expected to be
    # sorted, this is the ONLY range that can container "x".
    index = searchsortedfirst(V, x)

    # Make sure index is inbounds (if no range is found, index will be out of bounds), then
    # check if "x" is actually in the range.
    return (index <= length(V)) && in(x, V[index])
end

"""
    union(A::SortedRangeVector, B::SortedRangeVector)

Efficiently union `A` and `B` together.
"""
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

        push!(U, x)
        ix = iterate(X, sx)
    end

    return U
end

