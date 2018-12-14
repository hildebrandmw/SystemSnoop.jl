#####
##### Sample
#####

"""
Simple container containing the list of VMAs analyzed for a sample as well as the individual
pages accessed.

Fields
------

* `vmas :: Vector{VMA}` - The [`VMA`](@ref)s analyzed during this sample.

* `pages :: SortedRangeVector{UInt64}` - The pages that were active during this sample. Pages are
    encoded by virtual page number. To get an address, multiply the page number by the
    pagesize (generally 4096).

Methods
-------
* [`vmas`](@ref) - [`VMA`](@ref)s of `Sample`.
* [`pages`](@ref) - Active pages from `Sample` or `Vector{Sample}`.
* [`wss`](@ref) - Working set size of `Sample`.
* `union` - Merge two `Sample`s together.
* [`isactive`](@ref) - Check if a page was active in `Sample`.
* [`bitmap`](@ref) - Construct a bitmap of active pages for a `Vector{Sample}`.
"""
struct Sample
    vmas :: Vector{VMA}
    # Recording page number ...
    pages :: SortedRangeVector{UInt64}
end
vmas(S::Sample) = S.vmas
==(a::Sample, b::Sample) = (a.vmas == b.vmas) && (a.pages == b.pages)

function union(a::Sample, b::Sample)
    # Merge the two VMA regions
    vmas = compact(vcat(a.vmas, b.vmas)) 
    pages = union(a.pages, b.pages)

    return Sample(vmas, pages)
end

union(a::Sample, b::Sample, c::Sample, args::Sample...) = foldl(union, (a, b, c, args...))

"""
    wss(S::Sample) -> Int

Return the number of active pages for `S`.
"""
wss(S::Sample) = sumall(S.pages)
wss(S::Vector{Sample}) = wss.(S)

"""
    isactive(sample::Sample, page) -> Bool

Return `true` if `page` was active in `sample`.
"""
isactive(sample::Sample, page) = in(page, sample.pages)

"""
    bitmap(trace::Vector{Sample}, vma::VMA) -> Array{Bool, 2}

Return a bitmap `B` of active pages in `trace` with virtual addresses from `vma`. 
`B[i,j] == true` if the `i`th address in `vma` in `trace[j]` is active.
"""
function bitmap(trace::Vector{Sample}, vma::VMA)
    # Pre allocate the output array
    map = Array{Bool}(undef, length(vma), length(trace))  

    for (col, sample) in enumerate(trace)
        # Get the first index to start looking
        pages = sample.pages 
        index = searchsortedfirst(pages, vma.start)
        for (row, page) in enumerate(vma.start:vma.stop)
            if index < length(pages)
                if page > last(pages[index])
                    index += 1
                end

                map[row, col] = in(page, pages[index])
            else
                map[row, col] = in(page, pages[end])
            end
        end
    end

    return map
end

"""
    pages(sample::Sample) -> Set{UInt64}

Return a set of all active pages in `sample`.
"""
pages(sample::Sample) = Set(flatten(sample.pages))

"""
    vmas(trace::Vector{Sample}) -> Vector{VMA}

Return the largest sorted collection ``V`` of `VMA`s with the property that for any sample
``S \\in trace`` and for any `VMA` ``s \\in S``, ``s \\subset v`` for some ``v \\in V`` and
``s \\cap u = \\emptyset`` for all ``u \\in V \\setminus v``.o
"""
vmas(trace::Vector{Sample}) = mapreduce(vmas, (x,y) -> compact(union(x,y)), trace)


"""
    pages(trace::Vector{Sample}) -> Vector{UInt64}

Return a sorted vector of all pages in `trace` that were marked as "active" at least
once. Pages are encoded by virtual page number.
"""
pages(trace::Vector{Sample}) = mapreduce(pages, union, trace) |> collect |> sort
