############################################################################################
# Stack based analysis for rereference intervals and WSS estimation.

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


"""
Struct tracking various page use metrics for an application without keeping a whole trace
of page activity.

Fields
------

* `distances::Dict{Int,Int}` - Reuse distance count. Keys to the dictionary are (an upper 
    bound on) the number of unique pages accessed between subsequent accesses to an 
    individual page. Values of the dictionary are the count of that distance.

    The distances (keys) are an upper bound because of the discrete sampletime.

* `resident_pages::Vector{Int}` - The number of resident pages. Accessing `resident_pages[i]`
    gives the number of resident pages for sample window `i`.

* `active_pages::Vector{Int}` - The number of active pages.

* `vma_size::Vector{Int}` - Collective size of all the monitored VMA regions.

* `max_depth::Vector{Int}` - The maximum depth seen for a sample.
"""
Base.@kwdef struct DistanceTracker
    distances       :: Dict{Int,Int} = Dict{Int,Int}()
    resident_pages  :: Vector{Int} = Int[]
    active_pages    :: Vector{Int} = Int[]
    vma_size        :: Vector{Int} = Int[]
    max_depth       :: Vector{Int} = Int[] 
end


function transform(distances)
    maxdepth = maximum(keys(distances))
    v = [get(distances, k, 0) for k in 1:maxdepth]
    push!(v, distances[-1])
    v
end


function stackidle!(process, stack::BucketStack, tracker::DistanceTracker; buffer = process.bitmap)
    # Initialize counters and tracking variables
    active_pages   = 0
    resident_pages = 0
    max_size       = -1
    max_depth      = -1

    read!(IDLE_BITMAP, buffer)

    # The index of the VMA being referenced.
    vma_index = 1

    # Create a new entry in the bucketstack - run cleanup first to remove any empty entries.
    cleanup!(stack)
    pushfirst!(stack)

    walkpagemap(process.pid, process.vmas) do pagemap_region

        vma = process.vmas[vma_index]
        # Iterate over the pagemap entries. If an entry is in memory and not idle,
        # get its virtual frame number and update the bucket stack
        for (index, entry) in enumerate(pagemap_region)
            if inmemory(entry)
                resident_pages += 1
            end
            if isactive(entry, buffer)
                active_pages += 1
                frame = vma.start + index - 1
                depth = upstack!(stack, frame)
                increment!(tracker.distances, depth, 1)
                # Update the maximum depth tracker
                max_depth = max(max_depth, depth)
            end
        end

        # Book-keeping at the end of a loop.
        vma_index += 1
    end

    # Update tracker variables.
    push!(tracker.active_pages, active_pages)
    push!(tracker.resident_pages, resident_pages)
    push!(tracker.max_depth, max_depth)
    push!(tracker.vma_size, sum(length, process.vmas))

    nothing
end


"""
    track_distance(pid; [sampletime], [iter], [filter]) -> DistanceTracker

Return a [`DistanceTracker`](@ref) with memory usage statistics for the system process
with `pid`. Like [`Trace`](@ref), this function will gracefully exit when `pid` no longer
exists.

The general flow of this function is as follows:

1. Sleep for `sampletime`.
2. Pause `pid`.
3. Get the VMAs for `pid`, applying `filter`.
4. Read all of the active pages.
5. Mark all pages as idle.
6. Resume `pid.
7. Repeat for each element of `iter`.

Keyword Arguments
-----------------
* `sampletime` : Time between reading and reseting the idle page flags to determine page
    activity. Default: `2`

* `iter` : Iterator to control the number of samples to take. Default behavior is to keep
    sampling until monitored process terminates. Default: [`Forever()`](@ref)

* `filter` : Filter to apply to process `VMAs` to reduce total amount of memory tracked.
    Default: [`tautology`](@ref)
"""
function track_distance(pid; sampletime = 2, iter = Forever(), filter = tautology)
    process = Process{SeekWrite}(pid)

    stack = BucketStack{UInt}()
    tracker = DistanceTracker()
    try
        for _ in iter
            sleep(sampletime)
            pause(process)
            getvmas!(process.vmas, process.pid, filter)
            stackidle!(process, stack, tracker)
            markidle(process)
            resume(process)
        end

    # Catch errors that turn up because the PID no longer exists
    catch error
        isa(error, PIDException) || rethrow(error)
    end
    return tracker
end
