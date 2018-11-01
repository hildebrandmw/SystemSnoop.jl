############################################################################################
# Stack based analysis for rereference intervals and WSS estimation.

struct BucketStack{T}
    buckets::Vector{Set{T}}
end

BucketStack{T}() where T = BucketStack(Vector{Set{T}}())

# Standard iterator stuff
length(B::BucketStack) = length(B.buckets)
eltype(B::BucketStack) = eltype(B.buckete)
iterate(B::BucketStack, args...) = iterate(B.buckets, args...)
getindex(B::BucketStack, inds...) = getindex(B.buckets, inds...)

IteratorSize(::Type{BucketStack}) = HasLength()
IteratorEltype(::Type{BucketStack}) = HasEltype()

pushfirst!(B::BucketStack{T}) where T = pushfirst!(B.buckets, Set{T}())
pop!(B::BucketStack) = pop!(B.buckets)

function transform(distances)
    maxdepth = maximum(keys(distances))
    v = [get(distances, k, 0) for k in 1:maxdepth]
    push!(v, distances[-1])
    v
end


"""
    upstack!(stack::BucketStack, item) -> Int

Add `frame` to the first bucket of `bucketstack`. Delete `frame` from lower buckets in the
stack and return the depth of the frame. If `frame` was not previously found in 
`bucketstack`, return `-1`.
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

Base.@kwdef struct StackTracker
    distances       :: Dict{Int,Int} = Dict{Int,Int}()
    resident_pages  :: Vector{Int} = Int[]
    active_pages    :: Vector{Int} = Int[]
    vma_size        :: Vector{Int} = Int[]
    max_depth       :: Vector{Int} = Int[] 
end

function stackidle!(process, stack::BucketStack, tracker::StackTracker; buffer = process.bitmap)
    # Initialize counters and tracking variables
    active_pages   = 0
    resident_pages = 0
    max_size       = -1
    max_depth      = -1

    read!(IDLE_BITMAP, buffer)

    # The index of the VMA being referenced.
    vma_index = 1
    # Create a new entry in the bucketstack
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
        vma_index += 1
    end

    push!(tracker.active_pages, active_pages)
    push!(tracker.resident_pages, resident_pages)
    push!(tracker.max_depth, max_depth)
    push!(tracker.vma_size, sum(length, process.vmas))

    nothing
end


function trackstack(pid; sampletime = 2, iter = Forever(), filter = tautology)
    process = Process{SeekWrite}(pid)

    stack = BucketStack{UInt}()
    tracker = StackTracker()
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
