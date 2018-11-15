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
    nothing
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


function transform(distances)
    maxdepth = maximum(keys(distances))
    v = [get(distances, k, 0) for k in 1:maxdepth]
    push!(v, distances[-1])
    v
end
