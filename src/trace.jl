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
