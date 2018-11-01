module MemSnoop

const IDLE_BITMAP = "/sys/kernel/mm/page_idle/bitmap"

import Base.Iterators: repeated, drop
import Base: getindex, iterate, length, push!, pushfirst!, string, lastindex, eltype
import Base: IteratorSize, HasLength, IteratorEltype, HasEltype

using Serialization

# Check if huge pages are enabled and display a warning if they are.
function __init__()
    check_hugepages()
end

## Constants
############################################################################################

# Assumes all pages are 4kB. Deal with this later if it turns out that large pages are a
# thing in what we're monitoring
const PAGESIZE = 4096

# Size of a pagemap entry in bytes
const PAGEMAP_ENTRY_SIZE_BYTES = 8

include("util.jl")
include("process.jl")
include("launch.jl")
include("hugepages.jl")

include("analysis/trace.jl")
include("analysis/stack.jl")

############################################################################################


end # module
