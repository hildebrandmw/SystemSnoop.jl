abstract type IdleWriter end
struct AllWrite <: IdleWriter end
struct SeekWrite <: IdleWriter end

## AbstractProcess ##
abstract type AbstractProcess{W <: IdleWriter} end
pause(p::AbstractProcess) = pause(p.pid)
resume(p::AbstractProcess) = resume(p.pid)


struct Process{W <: IdleWriter} <: AbstractProcess{W}
    pid :: Int64
    vmas :: Vector{VMA}
    bitmap :: Vector{UInt64}
end

Process(pid::Integer) = Process{SeekWrite}(pid)

function Process{W}(pid::Integer) where {W <: IdleWriter}
    p = Process{W}(Int64(pid), Vector{VMA}(), UInt64[])
    initbuffer!(p)
    return p
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
    resize!(p.bitmap, nentries)
    return nothing
end

"""
    markidle(process::AbstractProcess)

TODO
"""
function markidle(process::AbstractProcess{SeekWrite})
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


function markidle(process::AbstractProcess{AllWrite})
    allones = Ref(typemax(UInt64))
    open(IDLE_BITMAP, "w") do bitmap
        for _ in 1:length(process.bitmap)
            unsafe_write(bitmap, allones, sizeof(UInt64))
        end
    end
    return nothing
end

