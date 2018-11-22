"""
    BucketStack{T}

Like a stack, but entries in the stack are buckets of elements rather than single elements.
This models the fact that we sample active pages over an interval and don't have an exact
trace.

Fields
------
* `buckets::Vector{Set{T}}`

Constructor
-----------
    
    BucketStack{T}()

Construct an empty `BucketStack` with element types `T`.
"""
struct BucketStack{T}
    buckets::Vector{Set{T}}
end

BucketStack{T}() where T = BucketStack(Vector{Set{T}}())

# Standard iterator stuff
length(B::BucketStack) = length(B.buckets)
eltype(B::BucketStack) = eltype(B.buckets)
iterate(B::BucketStack, args...) = iterate(B.buckets, args...)
getindex(B::BucketStack, inds...) = getindex(B.buckets, inds...)

IteratorSize(::Type{BucketStack}) = HasLength()
IteratorEltype(::Type{BucketStack}) = HasEltype()

pushfirst!(B::BucketStack{T}) where T = pushfirst!(B.buckets, Set{T}())

function cleanup!(B::BucketStack)
    # Find all the empty indices
    inds = findall(isempty, B.buckets) 
    deleteat!(B.buckets, inds)
    return nothing
end


"""
    upstack!(stack::BucketStack, item) -> Int

Add `item` to the first bucket of `stack`. Delete `item` from lower buckets in the
stack and return the depth of the item. If `item` was not previously found in 
`stack`, return `-1`.
"""
function upstack!(stack::BucketStack{T}, item::T) where T
    nitems = length(first(stack))
    # Push the frame to the first bucket since it was accessed.
    push!(first(stack), item)
    # Skip the first bucket in the stack
    for bucket in drop(stack, 1)
        nitems += length(bucket)
        if in(item, bucket)
            delete!(bucket, item)
            return nitems
        end 
    end
    return -1
end

function histogram(trace::Vector{Sample})
    distances = Dict{Int,Int}()

    # Make a bucket stack for finding distances
    stack = BucketStack{UInt64}()

    for sample in trace
        # Prepare the stack for a new iteration
        cleanup!(stack)
        pushfirst!(stack)

        # Record depths
        for page in flatten(sample.pages)
            depth = upstack!(stack, page)
            increment!(distances, depth, 1)
        end
    end

    return distances
end

function bin(x, f)
    return map(1:ceil(Int, length(x) / f)) do i
        # Generate the range
        start = f*(i-1)+1 
        stop = min(f*i, length(x))
        return sum(@view(x[start:stop]))
    end
end


function transform(distances)
    d = copy(distances)
    # Swap the entry at negative 1 to the end
    maxdepth = maximum(keys(d))
    d[maxdepth + 1] = d[-1]
    delete!(d, -1)

    return sparsevec(d)
end

function memoize!(d, pages::Vector, range)
    length(range) == 0 && return valtype(d)()

    # Return memoized item if it exists
    item = get(d, range, nothing)
    item != nothing && return item

    # End of recursion - only pass a singleton range
    if length(range) == 1
        result = pages[first(range)]
        d[range] = result
        return result
    else
        # Decrease range
        subrange = first(range):(last(range)-1)
        subresult = memoize!(d, pages, subrange)
        result = union(subresult, pages[last(range)])

        # Save result and return
        d[range] = result 
        return result
    end
end


function moveend!(d)
    m = maximum(keys(d))
    d[m+1] = d[-1]
    delete!(d, -1)
    return nothing
end


_histogram(trace::Vector{Sample}) = _histogram([s.pages for s in trace])

function _histogram(buckets::Vector{T}) where T
    # Upper and lower bounds on reuse distance
    lb = Dict{Int,Int}()
    ub = Dict{Int,Int}()

    # Index where each page was last seen
    lastseen = Dict{Int,Int}()

    # Memoize unions of consecutive ranges
    memoizer = Dict{UnitRange{Int64},T}()

    for (index, pages) in enumerate(buckets)
        @show index

        # Iterate through all items seen. 
        for page in flatten(pages)
            # Get the index where this page was last seen. If was not previously seen,
            # mark it as this index.
            lastindex = get!(lastseen, page, index)

            # Check if we just saw the page now
            if lastindex == index
                # Must mark both lower bound and upper bound as never having seen
                # this page before.
                increment!(lb, -1, 1)
                increment!(ub, -1, 1)
            else
                ub_distance = sumall(memoize!(memoizer, buckets, lastindex:index))
                increment!(ub, ub_distance+1, 1)

                lb_distance = sumall(memoize!(memoizer, buckets, (lastindex+1):(index-1)))
                increment!(lb, lb_distance+1, 1)
            end
        end
    end

    moveend!(lb)
    moveend!(ub)

    return (lb, ub)
end


