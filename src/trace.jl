#####
##### Sample
#####

"""
Simple container containing the list of VMAs analyzed for a sample as well as the individual
pages accessed.

Fields
------

* `vmas :: Vector{VMA}` - The VMAs analyzed during this sample.

* `pages :: SortedRangeVector{UInt64}` - The pages that were active during this sample. Pages are
    encoded by virtual page number. To get an address, multiply the page number by the
    pagesize (generally 4096).
"""
struct Sample
    vmas :: Vector{VMA}
    # Recording page number ...
    pages :: SortedRangeVector{UInt64}
end
vmas(S::Sample) = S.vmas

function union(a::Sample, b::Sample)
    # Merge the two VMA regions
    vmas = compact(vcat(a.vmas, b.vmas)) 
    pages = union(a.pages, b.pages)

    return Sample(vmas, pages)
end

"""
    wss(S::Sample) -> Int

Return the number of active pages for `S`.
"""
wss(S::Sample) = sumall(S.pages)

"""
    isactive(sample::Sample, page) -> Bool

Return `true` if `page` was active in `sample`.
"""
isactive(sample::Sample, page) = in(page, sample.pages)

# These could be implemented better.
bitmap(sample::Sample, vma::VMA) = [isactive(sample, p) for p in vma.start:vma.stop]

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

############################################################################################
# trace

"""
    trace(pid; [sampletime], [iter], [filter], [callback]) -> Vector{Sample}

Record the full trace of pages accessed by an application with `pid`. Function will
gracefully exit and return `Vector{Sample}` if process `pid` no longer exists.

The general flow of this function is as follows:

1. Sleep for `sampletime`.
2. Pause `pid`.
3. Get the VMAs for `pid`, applying `filter`.
4. Read all of the active pages.
5. Mark all pages as idle.
6. Call `callback`
7. Resume `pid.
8. Repeat for each element of `iter`.

Keyword Arguments
-----------------
* `sampletime` : Seconds between reading and reseting the idle page flags to determine page
    activity. Default: `2`

* `iter` : Iterator to control the number of samples to take. Default behavior is to keep
    sampling until monitored process terminates. Default: Run until program terminates.

* `filter` : Filter to apply to process `VMAs` to reduce total amount of memory tracked.

* `callback` : Optional callback for printing out status information (such as number 
    of iterations).
"""
function trace(pid; 
        sampletime = 2, 
        iter = Forever(), 
        filter = tautology, 
        callback = () -> nothing
    )
    trace = Sample[]
    process = Process(pid)

    try
        for i in iter
            sleep(sampletime)

            pause(process)
            # Get VMAs, read idle bits and set idle bits
            getvmas!(process, filter)
            pages = readidle(process)
            markidle(process)
            callback()
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
