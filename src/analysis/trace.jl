"""
    readidle(process::AbstractProcess)

TODO
"""
function readidle(process::AbstractProcess)
    active_pages = Vector{Vector{Int}}()
    buffer = process.bitmap
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
record(vma::VMA, indices) = ActiveRecord(vma, Set(UInt64.(PAGESIZE .* indices .+ vma.start)))


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
addresses(sample::Sample) = mapreduce(addresses, union, sample)


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
lastindex(T::Trace) = lastindex(T.samples)

IteratorSize(::Type{Trace}) = HasLength()
IteratorEltype(::Type{Trace}) = HasEltype()

"""
    addresses(trace::Trace) -> Vector{UInt64}

Return a sorted vector of all addresses in `trace` that were marked as "active" at least
once.
"""
addresses(trace::Trace) = (sort ∘ collect ∘ mapreduce)(addresses, union, trace)

############################################################################################
"""
Wrapper for a [`Trace`](@ref) that provides a lazy array behavior. Useful for generating
heatmaps or bitmaps for pages that were hit or not.
"""
struct HeatmapWrapper <: AbstractArray{Bool, 2}
    trace :: Trace
    addresses :: Vector{UInt64}
end

HeatmapWrapper(trace::Trace) = HeatmapWrapper(trace, addresses(trace))

IteratorSize(::Type{HeatmapWrapper}) = Base.HasShape{2}()
IteratorEltype(::Type{HeatmapWrapper}) = HasEltype()
eltype(::HeatmapWrapper) = Bool
length(H::HeatmapWrapper) = prod(size(H))

Base.size(H::HeatmapWrapper) = (length(H.addresses), length(H.trace))
Base.IndexStyle(::Type{HeatmapWrapper}) = Base.IndexCartesian()

getindex(H::HeatmapWrapper, x, y) = isactive(H.trace[y], H.addresses[x])

############################################################################################
# trace

function trace(pid; sampletime = 2, iter = Forever(), filter = tautology)
    trace = Trace()
    process = Process(pid)

    try
        for _ in iter
            sleep(sampletime)

            pause(process)
            # Get VMAs, read idle bits and set idle bits
            getvmas!(process, filter)
            index_vector = readidle(process)
            markidle(process)
            resume(process)

            # Construct a sample from the list of hit pages.
            push!(trace, sample(process.vmas, index_vector))
        end
    catch err
        @show err
        # Assume the "pause" failed - return the trace
        if isa(err, ErrorException)
            return trace
        # If some other error occurs, rethrow so we get better stack traces at the REPL.
        else
            rethrow(err)
        end
    end
    return trace
end
