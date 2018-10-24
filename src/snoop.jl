## AbstractProcess ##
abstract type AbstractProcess end

pause(p::AbstractProcess) = pause(p.pid)
resume(p::AbstractProcess) = resume(p.pid)

struct Process <: AbstractProcess
    pid :: Int64
    vmas :: Vector{VMA}
    bitmap :: Vector{UInt64}
end

function Process(pid::Integer) 
    p = Process(Int64(pid), Vector{VMA}(), UInt64[])
    initbuffer!(p)
    return p
end

"""
    initbuffer!(p::AbstractProcess)

Read once from `page_idle/bitmap` to get the size of the bitmap. Set the `bitmap` in
`p` to this size to avoid reallocation every time the bitmap is read.
"""
function initbuffer!(p::AbstractProcess)
    # Get the number of bytes in the bitmap
    # Since this isn't a normal file, normal methods like "filesize" or "seekend" don't
    # work, so we actually have to buffer the whole array once to get the size. Since this
    # only happens at the beginning of a trace, it's okay to pay this additional latency.
    nentries = open(IDLE_BITMAP) do bitmap
        buffer = reinterpret(UInt64, read(bitmap))
        return length(buffer)
    end
    resize!(p.bitmap, nentries)
    return nothing
end

"""
    markidle(process::AbstractProcess)

TODO
"""
function markidle(process::AbstractProcess)
    open(IDLE_BITMAP, "w") do bitmap
        walkpagemap(process.pid, process.vmas) do pagemap_region
            for entry in pagemap_region
                if inmemory(entry)
                    pfn = pfnmask(entry)
                    pos = 8 * div64(pfn)

                    seek(bitmap, pos)

                    # Faster write than plain "write"
                    unsafe_write(bitmap, Ref(typemax(UInt64)), sizeof(UInt64))
                end
            end
        end
    end
    return nothing
end

function markidle_all(process::AbstractProcess)
    open(IDLE_BITMAP, "w") do bitmap
        for _ in 1:length(process.bitmap)
        #while !eof(bitmap)
            unsafe_write(bitmap, Ref(typemax(UInt64)), sizeof(UInt64))
        end
    end
    nothing
end


"""
    readidle(process::AbstractProcess; buffer = UInt8[])

TODO
"""
function readidle(process::AbstractProcess; buffer = UInt64[])
    active_pages = Vector{Vector{Int}}()
    # Read the whole idle bitmap buffer. This can take a while for systems with a large
    # amound of memory.
    read!(IDLE_BITMAP, buffer)
    walkpagemap(process.pid, process.vmas) do pagemap_region
        active_indices = Vector{Int}()
        for (index, entry) in enumerate(pagemap_region)
            # Check if the active bit for this page is set. If so, add this frame's index
            # to the collection of active indices.
            if isactive(entry, buffer)
                push!(active_indices, index - 1)
            end
        end
        push!(active_pages, active_indices)
    end

    return active_pages
end

############################################################################################


"""
Record of the active (non-idle) pages within a Virtual Memory Area (VMA)

Fields
------

* `vma::VMA` - The VMA that this record is for.
* `address::Vector{UInt64}` - The virtual page addresses within this VMA that were active.
"""
struct ActiveRecord
    vma :: VMA
    addresses :: Set{UInt64}
end

addresses(record::ActiveRecord) = record.addresses

# Resolve the offset indices returned by "readidle" to the actual pages within the VMA
# that were hit.
record(vma::VMA, indices) = ActiveRecord(vma, Set(UInt64.(PAGESIZE .* indices) .+ vma.start))


############
## Sample ##
############

struct Sample
    records :: Vector{ActiveRecord}
end

sample(vmas, indices) = Sample(record.(vmas, indices))

# Convenience methods
length(S::Sample) = length(S.records)
eltype(S::Sample) = eltype(S.records)
iterate(S::Sample, args...) = iterate(S.records, args...)
getindex(S::Sample, inds...) = getindex(S.records, inds...)

IteratorSize(::Type{Sample}) = HasLength()
IteratorEltype(::Type{Sample}) = HasEltype()

"""
    isactive(sample::Sample, address) -> Bool

Return `true` if `address` was active in `sample`.
"""
isactive(sample::Sample, address::UInt) = any(x -> in(address, x.addresses), sample)

"""
    addresses(sample::Sample) -> Set{UInt64}

Return a set of all active addresses in `sample`.
"""
addresses(sample::Sample) = reduce(union, addresses.(sample))


############################################################################################
# Trace
struct Trace
    samples :: Vector{Sample}
end
Trace() = Trace(Sample[])
push!(T::Trace, S::Sample) = push!(T.samples, S)
length(T::Trace) = length(T.samples)
eltype(T::Trace) = eltype(T.samples)
iterate(T::Trace, args...) = iterate(T.samples, args...)
getindex(T::Trace, inds...) = getindex(T.samples, inds...)

IteratorSize(::Type{Trace}) = HasLength()
IteratorEltype(::Type{Trace}) = HasEltype()

"""
    addresses(trace::Trace) -> Vector{UInt64}

Return a sorted vector of all addresses in `trace` that were marked as "active" at least
once.
"""
addresses(trace::Trace) = (sort ∘ collect ∘ reduce)(union, addresses.(trace))


############################################################################################
# trace

function trace(pid; sampletime = 2)
    trace = Trace()
    process = Process(pid)

    try
        while true
            sleep(sampletime)

            pause(process)
            # Get VMAs, read idle bits and set idle bits
            getvmas!(process.vmas, process.pid)
            index_vector = readidle(process; buffer = process.bitmap)
            markidle(process)
            resume(process)

            # Construct a sample from the list of hit pages.
            push!(trace, sample(process.vmas, index_vector))
        end
    catch err
        # Assume the "pause" failed - return the trace
        if isa(err, ErrorException)
            return trace
        # If some other error occurs, rethrow so we get better stack traces at the REPL.
        else
            rethrow(err)
        end
    end
end


############################################################################################
# Stack based analysis for rereference intervals and WSS estimation.
#

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


function transform(distances)
    maxdepth = maximum(keys(distances))
    v = [get(distances, k, 0) for k in 1:maxdepth]
    push!(v, distances[-1])
    v
end

function cdf(x) 
    s = sum(x)
    c = [first(x) / s]
    for i in drop(x, 1)
        push!(c, last(c) + (i / s))
    end
    c 
end

"""
    upstack!(stack::BucketStack, item) -> Tuple{Int,Int}

Add `frame` to the first bucket of `bucketstack`. Delete `frame` from lower buckets in the
stack and return the depth of the frame. If `frame` was not previously found in 
`bucketstack`, return `-1`.
"""
function upstack!(stack::BucketStack{T}, item::T) where T
    # Push the frame to the first bucket since it was accessed.
    push!(first(stack), item)
    nitems = length(first(stack)) - 1
    # Skip the first bucket in the stack
    for (depth, bucket) in enumerate(drop(stack, 1))
        nitems += length(bucket)
        if item in bucket
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


function trackstack(pid; sampletime = 2)
    process = Process(pid)

    stack = BucketStack{UInt}()
    tracker = StackTracker()
    try
        while true
            sleep(sampletime)
            pause(process)
            getvmas!(process.vmas, process.pid)
            stackidle!(process, stack, tracker)
            markidle_all(process)
            resume(process)
        end

    catch err
        return tracker
    end
end

"""
    save(file::String, trace::Trace)

Serialize `trace` for `file`.
"""
save(file::String, trace::Trace) = open(f -> serialize(f, trace), file, "w")
