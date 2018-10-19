module MemSnoop

const IDLE_BITMAP = "/sys/kernel/mm/page_idle/bitmap"

using Base.Iterators: repeated

tautology(args...) = true

pagesize() = 4096
pageshift() = (Int ∘ log2)(pagesize())

const PAGEMAP_ENTRY_SIZE = 8

# Get the lower 55 bits
pagemapmask(x) = x & (~(UInt(0x1ff) << 55))
# Ch
indram(x) = !iszero(x & (1 << 63))

div64(x) = x >> 6
mod64(x) = x & 63
isbitset(x, b) = !iszero(x & (1 << b))

pause(pid) = run(`kill -STOP $pid`)
resume(pid) = run(`kill -CONT $pid`)

# TODO: Could make this lazy ... 
# TODO: Make this mutating on a supplied array of bytes to avoid allocating every time.
# TODO: Operate on the underlying bytes directly to avoid allocating strings.
function vmranges(pid, filter = tautology)
    # maps/ entries look like this
    #
    # 0088f000-010fe000 rw-p 00000000 00:00 0
    #
    # Where the first pair of numbers is the range of addresses for this unit.
    # The strategy here is to find up to the first "-", parse as an int, then parse to the
    # next " "
    ranges = UnitRange{UInt64}[]
    open("/proc/$pid/maps") do f
        while !eof(f)
            start = parse(UInt, readuntil(f, '-'); base = 16)
            stop = parse(UInt, readuntil(f, ' '); base = 16) - one(UInt)

            # Wrap to the next line
            remainder = readuntil(f, '\n') 
            filter(start, stop, remainder) || continue

            push!(ranges, start:stop)
        end
    end

    return ranges
end


# NOTE: Can definitely clean this up, especially by filtering addresses from above
function translate(pid, vmranges)
    physical_pages = UInt64[]
    buffer = UInt8[]
    # Read all of the pagemap
    open("/proc/$pid/pagemap") do f
        for range in vmranges
            # Shift the raw range above into indices into the pagemap
            
            start = PAGEMAP_ENTRY_SIZE * first(range) >> pageshift() 
            stop = PAGEMAP_ENTRY_SIZE * last(range) >> pageshift()
            nbytes = stop - start
            # Seek to the start address.
            seek(f, start) 

            # 1. Read the requested number of bytes 
            # 2. cast the array to UInt64 since that's the size of each entry in the pagemap
            # 3. Mask out the bits at the top to get the PFN
            empty!(buffer) 
            readbytes!(f, buffer, nbytes)
            entries = reinterpret(UInt64, buffer) 
            for entry in entries
                if indram(entry)
                    push!(physical_pages, pagemapmask(entry))
                end
            end
        end
    end
    sort!(physical_pages)
    return physical_pages
end


function markidle(pages)
    open(IDLE_BITMAP, "w") do f
        for page in pages
            seek(f, 8 * div64(page))
            # Just write a whole bunch of ones, don't try to be too accurate.
            write(f, typemax(UInt64))
        end
    end
end


function readidle(pages)
    active = BitVector(undef, length(pages))

    # Read the number of bits up to the highest bit in the pages
    # Remember that pages are sorted, so we can just grab the last pages to get the highest
    # physical address
    nwords = div64(last(pages))
    bitmap = reinterpret(UInt64, read(IDLE_BITMAP, 8 * nwords))

    # Read the idle bits
    for (index, page) in enumerate(pages)
        chunk = bitmap[div64(page)]
        active[index] = ~isbitset(chunk, mod64(page))
    end
    return active
end


function snoop(pid; downtime = 1.0, nsamples = 30)
    active_pages = Vector{Vector{UInt64}}() 

    # Mark these pages as idle
    for i in 1:nsamples 
        println("On Sample $i")
        pause(pid)
        # Get the physical pages for snooping.    
        pages = translate(pid, vmranges(pid))
        markidle(pages)
        resume(pid)

        sleep(downtime)

        pause(pid)
        activebits = readidle(pages)
        resume(pid)

        # Store the pages that were accessed.
        push!(active_pages, pages[activebits])
    end

    return active_pages
end


end # module
