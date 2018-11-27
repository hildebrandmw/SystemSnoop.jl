## AbstractProcess ##
abstract type AbstractProcess end
pause(p::AbstractProcess) = pause(p.pid)
resume(p::AbstractProcess) = resume(p.pid)

struct Process <: AbstractProcess
    pid :: Int64
    vmas :: Vector{VMA}
    buffer :: Vector{UInt64}

    function Process(pid::Integer)
        # Create the object
        p = new(Int64(pid), Vector{VMA}(), UInt64[])

        # Initialize the buffer to be the correct size to hold the entire idle page bitmap
        initbuffer!(p)
        return p
    end
end

getvmas!(process::AbstractProcess, args...) = getvmas!(process.vmas, process.pid, args...)

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
    resize!(p.buffer, nentries)
    return nothing
end

#####
##### Page Walking Functions
#####

"""
    walkpagemap(f::Function, pid, vmas; [buffer::Vector{UInt64}])

For each [`VMA`](@ref) in iterator `vmas`, store the contents of `/proc/pid/pagemap` into
`buffer` for this `VMA` and call `f(buffer)`.

Note that it is possible for `buffer` to be empty.
"""
function walkpagemap(f::Function, pid, vmas; buffer::Vector{UInt64} = UInt64[])
    # Open the pagemap file. Expect address ranges for the VMAs to be in order.
    try 
        open("/proc/$pid/pagemap") do pagemap
            for vma in vmas

                # Seek to the start address.
                seek(pagemap, vma.start * sizeof(UInt64))
                if eof(pagemap)
                    empty!(buffer)
                else
                    resize!(buffer, length(vma))
                    read!(pagemap, buffer)
                end

                # Call the passed function
                f(buffer)
            end
        end
    catch error
        # Check the error, if it's a "file not found (errnum=2)", throw a PID error to escape,
        if isa(error, SystemError) && error.errnum == 2
            throw(PIDException(pid))
        else
            rethrow(error)
        end
    end
    return nothing
end

"""
    markidle(process::AbstractProcess)

TODO
"""
function markidle(process::AbstractProcess)
    open(IDLE_BITMAP, "w") do bitmap

        # Keep track of positions in the bitmap file that have already been written to.
        # Avoids reseeking and rewriting of positions already marked as idle.
        positions = Set{UInt64}()

        walkpagemap(process.pid, process.vmas) do pagemap_region
            for entry in pagemap_region
                if inmemory(entry)
                    pfn = pfnmask(entry)
                    pos = 8 * div64(pfn)

                    if !in(pos, positions)
                        # Mark this position as read
                        push!(positions, pos)

                        # Seek and write
                        seek(bitmap, pos)
                        write(bitmap, typemax(UInt64))
                    end
                end
            end
        end
    end
    return nothing
end

"""
    readidle(process::AbstractProcess) -> Vector{SortedRangeVector{Int}}

TODO
"""
function readidle(process::AbstractProcess)
    pages = SortedRangeVector{UInt64}()
    buffer = process.buffer
    # Read the whole idle bitmap buffer. This can take a while for systems with a large
    # amound of memory.
    read!(IDLE_BITMAP, buffer)

    # Index of the VMA currently being accessed.
    vma_index = 1

    walkpagemap(process.pid, process.vmas) do pagemap_region
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
