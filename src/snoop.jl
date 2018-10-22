## AbstractProcess ##
abstract type AbstractProcess end

pause(p::AbstractProcess) = pause(p.pid)
resume(p::AbstractProcess) = resume(p.pid)

struct Process <: AbstractProcess
    pid :: Int64
    vmas :: Vector{VMA}
end

Process(pid::Integer) = Process(Int64(pid), Vector{VMA}())


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
    buffer = reinterpret(UInt64, read(IDLE_BITMAP))
    walkpagemap(process.pid, process.vmas) do pagemap_region
        active_bitmap = Vector{Int}()
        for (index, entry) in enumerate(pagemap_region)

            if inmemory(entry)
                pfn = pfnmask(entry)
                # Convert from 0-based to 1-based indexing
                chunk = buffer[div64(pfn) + 1]

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
    addresses :: Vector{UInt64}
end

addresses(record::ActiveRecord) = record.addresses

# Resolve the offset indices returned by "readidle" to the actual pages within the VMA
# that were hit.
record(vma::VMA, indices) = ActiveRecord(vma, UInt64.(PAGESIZE .* indices) .+ vma.start)


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
addresses(sample::Sample) = reduce(union, Set.(addresses.(sample)))


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


function snoop(pid; sampletime = 2)
    trace = Trace()
    process = Process(pid)

    try
        while true

            sleep(sampletime)

            pause(process)
            getvmas!(process.vmas, process.pid)
            index_vector = readidle(process)

            # Construct a sample from the list of hit pages.
            push!(trace, sample(process.vmas, index_vector))
            markidle(process)
            resume(process)
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
