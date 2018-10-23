module MemSnoop

const IDLE_BITMAP = "/sys/kernel/mm/page_idle/bitmap"

import Base.Iterators: repeated, drop
import Base: getindex, iterate, length, push!
import Base: IteratorSize, HasLength, IteratorEltype, HasEltype

using Serialization

## Constants
############################################################################################

# Assumes all pages are 4kB. Deal with this later if it turns out that large pages are a
# thing in what we're monitoring
const PAGESIZE = 4096

# Size of a pagemap entry in bytes
const PAGEMAP_ENTRY_SIZE_BYTES = 8

include("util.jl")
include("snoop.jl")
include("launch.jl")

############################################################################################


end # module
