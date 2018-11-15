
"""
Compact representation of data of type `T` that is both sorted and usually occurs in
contiguous ranges. For example, since groups of virtual memory pages are usually accessed
together, a `RangeVector` can encode those more compactly than a normal vector.

Fields
------

* `ranges :: Vector{UnitRange{T}` - The elements of the `RangeVector`, compacted into
    contiguous ranges.

Constructor
-----------

    RangeVector{T}() -> RangeVector{T}

Construct a empty `RangeVector` with element type `T`.
"""
struct RangeVector{T}
    ranges::Vector{UnitRange{T}}
end
RangeVector{T}() where {T} = RangeVector{T}(UnitRange{T}[])

# Convenience methods
length(R::RangeVector) = isempty(R.ranges) ? 0 : sum(length, R.ranges)
eltype(R::RangeVector{T}) where {T} = T
iterate(R::RangeVector, args...) = iterate(Iterators.flatten(R.ranges), args...)
IteratorEltype(::Type{<:RangeVector}) = HasEltype()
IteratorSize(::Type{<:RangeVector}) = HasLength()

"""
    lastelement(R::RangeVector{T}) -> T

Return the last element of the last range of `R`.
"""
lastelement(R::RangeVector) = (last ∘ last)(R.ranges)

"""
    push!(R::RangeVector{T}, x::T)

Add `x` to the end of `R`, merging `x` into the final range if appropriate.
"""
function push!(R::RangeVector{T}, x::T) where T
    # Check to see if `x` can be appended to the last element of `R`.
    if !isempty(R.ranges) && (x - lastelement(R)) == one(T)
        R.ranges[end] = (first ∘ last)(R.ranges):x
    else
        push!(R.ranges, x:x)
    end
    nothing
end

"""
    insorted(R::RangeVector, x) -> Bool

Perform an efficient search of `R` for item `x`, assuming the ranges in `R` are sorted and
non-overlapping.
"""
function insorted(R::RangeVector, x)
    ranges = R.ranges
    # Find the first range that can possibly contain "x". Since ranges are expected to be
    # sorted, this is the ONLY range that can container "x".
    index = searchsortedfirst(ranges, x; lt = (y, x) -> (last(y) < x))

    # Make sure index is inbounds (if no range is found, index will be out of bounds), then
    # check if "x" is actually in the range.
    return (index < length(ranges)) && in(x, ranges[index])
end

############################################################################################

"""
    readidle(process::AbstractProcess) -> Vector{RangeVector{Int}}

TODO
"""
function readidle(process::AbstractProcess)
    pages = RangeVector{UInt64}()
    buffer = process.bitmap
    # Read the whole idle bitmap buffer. This can take a while for systems with a large
    # amound of memory.
    read!(IDLE_BITMAP, buffer)

    # Index of the VMA currently being accessed.
    vma_index = 1

    walkpagemap(process.pid, process.vmas) do pagemap_region
        active_indices = RangeVector{Int}()
        for (index, entry) in enumerate(pagemap_region)
            vma = process.vmas[vma_index]
            # Check if the active bit for this page is set. If so, add this frame's index
            # to the collection of active indices.
            if isactive(entry, buffer)
                # Convert to page number and add to pages
                pagenumber = (index - 1) + vma.start
                push!(pages, pagenumber)
            end
        end
        vma_index += 1
    end

    return pages
end

############################################################################################

############
## Sample ##
############

"""
Simple container containing the list of VMAs analyzed for a sample as well as the individual
pages accessed.

Fields
------

* `vmas :: Vector{VMA}` - The VMAs analyzed during this sample.

* `pages :: RangeVector{UInt64}` - The pages that were active during this sample. Pages are
    encoded by virtual page number. To get an address, multiply the page number by the
    pagesize (generally 4096).
"""
struct Sample
    vmas :: Vector{VMA}
    # Recording page number ...
    pages :: RangeVector{UInt64}
end

vmas(S::Sample) = S.vmas

IteratorSize(::Type{Sample}) = HasLength()
IteratorEltype(::Type{Sample}) = HasEltype()


function getvma(S::Sample, page)
    index = searchsortedfirst(S.vmas, page; lt = (vma, page) -> (vma.stop < page))
    if index < length(S) && S.vmas[index].start <= page
        return S.vmas[index]
    else
        return nothing
    end
end

"""
    isactive(sample::Sample, page) -> Bool

Return `true` if `page` was active in `sample`.
"""
isactive(sample::Sample, page) = insorted(sample.pages, page)


# These could be implemented better.
gettrace(sample::Sample, vma::VMA) = [isactive(sample, p) for p in vma.start:vma.stop]
gettrace(samples::Vector{Sample}, vma::VMA) =
    [isactive(s,p) for p in vma.start:vma.stop, s in samples]


"""
    pages(sample::Sample) -> Set{UInt64}

Return a set of all active pages in `sample`.
"""
pages(sample::Sample) = Set(sample.pages)

vmas(trace::Vector{Sample}) = mapreduce(vmas, (x,y) -> compact(union(x,y)), trace)

"""
    pages(trace::Trace) -> Vector{UInt64}

Return a sorted vector of all pages in `trace` that were marked as "active" at least
once. Pages are encoded by virtual page number.
"""
function pages(trace::Vector{Sample})
    pgs = Set{UInt64}()
    for (index, sample) in enumerate(trace)
        union!(pgs, pages(sample))
    end
    return (sort ∘ collect)(pgs)
end

############################################################################################
# trace

"""
    trace(pid; [sampletime], [iter], [filter]) -> Vector{Sample}

Record the full trace of pages accessed by an application with `pid`. Function will
gracefully exit and return `Vector{Sample}` if process `pid` no longer exists.

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
* `sampletime` : Seconds between reading and reseting the idle page flags to determine page
    activity. Default: `2`

* `iter` : Iterator to control the number of samples to take. Default behavior is to keep
    sampling until monitored process terminates. Default: [`Forever()`](@ref)

* `filter` : Filter to apply to process `VMAs` to reduce total amount of memory tracked.
    Default: [`tautology`](@ref)
"""
function trace(pid; sampletime = 2, iter = Forever(), filter = tautology)
    trace = Sample[]
    process = Process(pid)

    try
        for _ in iter
            sleep(sampletime)

            pause(process)
            # Get VMAs, read idle bits and set idle bits
            getvmas!(process, filter)
            pages = readidle(process)
            markidle(process)
            resume(process)

            # Construct a sample from the list of hit pages.
            # Need to actually copy the VMAs.
            push!(trace, Sample(copy(process.vmas), pages))
        end
    catch error
        isa(error, PIDException) || rethrow(error)
    end
    return trace
end


############################################################################################
"""
Wrapper for a [`Vector{Sample}`](@ref) that provides a lazy array behavior. Useful for
generating heatmaps or bitmaps for pages that were hit or not.

Constructor
-----------

    ArrayView(trace::Trace)

Construct a `HeadmapWrapper` from `trace`.
"""
struct ArrayView <: AbstractArray{Bool, 2}
    trace :: Vector{Sample}
    pages :: Vector{UInt64}
end

ArrayView(trace::Vector{Sample}) = ArrayView(trace, pages(trace))

IteratorSize(::Type{ArrayView}) = Base.HasShape{2}()
IteratorEltype(::Type{ArrayView}) = HasEltype()
eltype(::ArrayView) = Bool
length(H::ArrayView) = prod(size(H))

Base.size(H::ArrayView) = (length(H.pages), length(H.trace))
Base.IndexStyle(::Type{ArrayView}) = Base.IndexCartesian()

getindex(H::ArrayView, x, y) = isactive(H.trace[y], H.pages[x])

getpage(H::ArrayView, x) = H.pages[x]
getvma(H::ArrayView, x, y) = getvma(H.trace[y], H.pages[x])
