module MemSnoop

const IDLE_BITMAP = "/sys/kernel/mm/page_idle/bitmap"

import Base.Iterators: repeated, drop, flatten
import Base: getindex, iterate, length, push!, pushfirst!, string, lastindex, eltype 
import Base: searchsortedfirst, size
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
const PAGESHIFT = (Int ∘ log2)(PAGESIZE)

include("hugepages.jl")
include("vma.jl")
include("util.jl")
include("process.jl")
include("launch.jl")
include("trace.jl")
include("analysis.jl")

#include("analysis/distance.jl")

############################################################################################


end # module
