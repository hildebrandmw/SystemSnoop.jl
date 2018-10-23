## AbstractProcess ##
abstract type AbstractProcess end

pause(p::AbstractProcess) = pause(p.pid)
resume(p::AbstractProcess) = resume(p.pid)

struct Process <: AbstractProcess
    pid :: Int64
    vmas :: Vector{VMA}
    bitmap :: Vector{UInt8}
end

function Process(pid::Integer) 
    p = Process(Int64(pid), Vector{VMA}(), UInt8[])
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
    nbytes = open(IDLE_BITMAP) do bitmap
        buffer = read(bitmap)
        return length(buffer)
    end
    resize!(p.bitmap, nbytes)
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


"""
    readidle(process::AbstractProcess; buffer = UInt8[])

TODO
"""
function readidle(process::AbstractProcess; buffer = UInt8[])
    active_pages = Vector{Vector{Int}}()
    # Read the whole idle bitmap buffer. This can take a while for systems with a large
    # amound of memory.
    read!(IDLE_BITMAP, buffer)
    bitmap = reinterpret(UInt64, buffer)
    walkpagemap(process.pid, process.vmas) do pagemap_region
        active_bitmap = Vector{Int}()
        for (index, entry) in enumerate(pagemap_region)

            if inmemory(entry)
                pfn = pfnmask(entry)
                # Convert from 0-based to 1-based indexing
                chunk = bitmap[div64(pfn) + 1]

                if !isbitset(chunk, mod64(pfn))
                    push!(active_bitmap, index - 1)
                end
            end
        end
        push!(active_pages, active_bitmap)
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

increment!(d::AbstractDict, k, v) = haskey(d, k) ? (d[k] += v) : (d[k] = v)

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
    upstack!(bucketstack, frame) -> Int

Add `frame` to the first bucket of `bucketstack`. Delete `frame` from lower buckets in the
stack and return the depth of the frame. If `frame` was not previously found in 
`bucketstack`, return `-1`.
"""
function upstack!(bucketstack, frame)
    # Push the frame to the first bucket since it was accessed.
    push!(first(bucketstack), frame)
    nframes = length(first(bucketstack)) - 1
    # Skip the first bucket in the stack
    for bucket in drop(bucketstack, 1)
        nframes += length(bucket)
        if frame in bucket
            delete!(bucket, frame)
            return nframes
        end 
    end
    return -1
end

function stackidle!(process, bucketstack, distances; buffer = process.bitmap)
    read!(IDLE_BITMAP, buffer)
    bitmap = reinterpret(UInt64, buffer)
    # The index of the VMA being referenced.
    vma_index = 1
    # Create a new entry in the bucketstack
    pushfirst!(bucketstack, Set{Int}())
    walkpagemap(process.pid, process.vmas) do pagemap_region
        vma = process.vmas[vma_index]
        # Iterate over the pagemap entries. If an entry is in memory and not idle,
        # get its virtual frame number and update the bucket stack
        for (index, entry) in enumerate(pagemap_region)
            if inmemory(entry)
                pfn = pfnmask(entry)
                chunk = bitmap[div64(pfn) + 1]

                if !isbitset(chunk, mod64(pfn))
                    frame = vma.start + index - 1
                    depth = upstack!(bucketstack, frame)
                    increment!(distances, depth, 1)
                end
            end
        end
    end
    nothing
end


function stack(pid; sampletime = 2)
    process = Process(pid)

    bucketstack = Vector{Set{UInt}}()
    distances = Dict{Int,Int}() 

    try
        while true
            sleep(sampletime)
            pause(process)
            getvmas!(process.vmas, process.pid)
            stackidle!(process, bucketstack, distances)
            markidle(process)
            resume(process)
        end

    catch err
        return distances
    end
end

"""
    save(file::String, trace::Trace)

Serialize `trace` for `file`.
"""
save(file::String, trace::Trace) = open(f -> serialize(f, trace), file, "w")
