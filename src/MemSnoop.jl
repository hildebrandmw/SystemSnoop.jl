module MemSnoop

const IDLE_BITMAP = "/sys/kernel/mm/page_idle/bitmap"

import Base.Iterators: repeated
import Base: length, push!

include("tester.jl")

## Constants
############################################################################################

# Assumes all pages are 4k. Deal with this later if it turns out that large pages are a
# thing in what we're monitoring
const PAGESIZE = 4096

# Size of a pagemap entry in bytes
const PAGEMAP_ENTRY_SIZE_BYTES = 8


## Helper Functions
############################################################################################

"""
    pfnmask(x::UInt) -> UInt

Return the lower 55 bits of `x`. When applied to a `/proc/pid/pagemap` entry, returns the
physical page number (pfn) of that entry.

NOTE: If the returned result is `zero(UInt64)`, the virtual page is not resident in memory.
"""
pfnmask(x) = x & (~(UInt(0x1ff) << 55))

div64(x::Integer) = x >> 6
mod64(x::Integer) = x & 63

"""
    isbitset(x::Integer, b::Integer) -> Bool

Return `true` if bit `b` of `x` is `1`.
"""
isbitset(x::Integer, b) = !iszero(x & (1 << b))


"""
    pause(pid)

Pause process with `pid`.
"""
pause(pid) = run(`kill -STOP $pid`)


"""
    resume(pid)

Resume process with `pid`.
"""
resume(pid) = run(`kill -CONT $pid`)


"""
    slurpbytes!(file::String, b::AbstractVector{UInt8}, nb=length(b))

Read at most `nb` bytes from `file` into `b`, returning the number of bytes read. The size
of `b` will be increased if needed, but it will never be decreased.
"""
slurpbytes!(file::String, b, nb = length(b)) = open(x -> readbytes!(x, b, nb), file)

## Types
############################################################################################


## VMA ##
# Representation of an OS level VMA. Each process consists of multiple VMAs
struct VMA
    start :: UInt64
    stop :: UInt64
end

length(vma::VMA) = vma.stop - vma.start
function translate(vma::VMA; entrysize = PAGEMAP_ENTRY_SIZE_BYTES, shift = (Int ∘ log2)(PAGESIZE))
    start = entrysize * vma.start >> shift
    stop = entrysize * vma.stop >> shift
    return start, stop
end

# VMA Filters
tautology(args...) = true
heap_filter(::VMA, remainder) = occursin("heap", remainder)


## AbstractProcess ##
abstract type AbstractProcess end

pause(p::AbstractProcess) = pause(p.pid)
resume(p::AbstractProcess) = resume(p.pid)

struct Process <: AbstractProcess
    pid :: Int64
    vmas :: Vector{VMA}
end

Process(pid::Integer) = Process(Int64(pid), Vector{VMA}())

# TODO: Operate on the underlying bytes directly to avoid allocating strings.
function getvmas!(buffer::Vector{VMA}, pid, filter = tautology)
    # maps/ entries look like this
    #
    # 0088f000-010fe000 rw-p 00000000 00:00 0
    #
    # Where the first pair of numbers is the range of addresses for this unit.
    # The strategy here is to find up to the first "-", parse as an int, then parse to the
    # next " "
    empty!(buffer)
    open("/proc/$pid/maps") do f
        while !eof(f)
            start = parse(UInt, readuntil(f, '-'); base = 16)
            stop = parse(UInt, readuntil(f, ' '); base = 16) - one(UInt)

            # Wrap to the next line
            remainder = readuntil(f, '\n')
            vma = VMA(start, stop)
            filter(vma, remainder) || continue

            push!(buffer, VMA(start, stop))
        end
    end
    return nothing
end


"""
    walkpagemap(f, pid, vmas::Vector{VMA}; [buffer::Vector{UInt8}])

TODO
"""
function walkpagemap(f, pid, vmas::Vector{VMA}; buffer::Vector{UInt8} = UInt8[])
    # Open the pagemap file. Expect address ranges for the VMAs to be in order.
    open("/proc/$pid/pagemap") do pagemap
        for vma in vmas

            start, stop = translate(vma)
            nbytes = stop - start
            # Seek to the start address.
            seek(pagemap, start)

            empty!(buffer)
            readbytes!(pagemap, buffer, nbytes)
            entries = reinterpret(UInt64, buffer)

            # Call the passed function
            f(entries)
        end
    end
end

############################################################################################


function markidle(process::AbstractProcess)
    open(IDLE_BITMAP, "w") do bitmap
        walkpagemap(process.pid, process.vmas) do pagemap_entries
            for entry in pagemap_entries
                pfn = pfnmask(entry)
                if pfn != 0
                    seek(bitmap, div64(pfn))
                    write(bitmap, typemax(UInt64))
                end
            end
        end
    end
    return nothing
end


function readidle(process::AbstractProcess; buffer = UInt8[])
    active_pages = Vector{Set{Int}}()
    # Read the whole idle bitmap buffer. This can take a while for systems with a large
    # amound of memory.
    buffer = reinterpret(UInt64, read(IDLE_BITMAP))
    walkpagemap(process.pid, process.vmas) do pagemap_entries
        active_bitmap = Set{Int}()
        for (index, entry) in enumerate(pagemap_entries)
            pfn = pfnmask(entry)

            if pfn != 0
                chunk = buffer[div64(pfn)]
                active = ~isbitset(chunk, mod64(pfn))
                active  && push!(active_bitmap, index)
            end
        end
        push!(active_pages, active_bitmap)
    end

    return active_pages
end

############################################################################################
#
#

struct ActivePages
    vma :: VMA
    hits :: Vector{Int}
end


struct Sample
    pages :: Vector{ActivePages}
end

function process_sample(vmas::Vector{VMA}, indices::Vector{Set{Int}})
    pages = ActivePages[]
    for (vma, index) in zip(vmas, indices)
        translated_pages = sort([i + vma.start for i in index])
        push!(pages, ActivePages(vma, translated_pages))
    end

    return Sample(pages)
end


struct Trace
    samples :: Vector{Sample}
end
Trace() = Trace(Sample[])
push!(T::Trace, S::Sample) = push!(T.samples, S)


function snoop(pid; sampletime = 2)
    trace = Trace()
    process = Process(pid)

    try
        while true

            sleep(sampletime)

            pause(process)
            getvmas!(process.vmas, process.pid, heap_filter)
            pages = readidle(process)

            # Construct a sample from the list of hit pages.
            sample = process_sample(process.vmas, pages)

            push!(trace, sample)
            markidle(process)
            resume(process)
        end
    catch err
        @show err
        return trace
    end
end



end # module
