module SystemSnoop

const IDLE_BITMAP = "/sys/kernel/mm/page_idle/bitmap"

import Base: isless, length, issubset, union, compact, ==, tail
import Base: iterate, size, getindex, searchsortedfirst, push!, in, IteratorSize, IteratorEltype
import Base.Iterators: flatten, take, drop

using Serialization, Dates, RecipesBase

export  trace, 
        # process traits
        SnoopedProcess, Pausable, Unpausable


#####
##### Constants
#####

# Assumes all pages are 4kB. Hugepage check is performed during initialization
# to ensure that this holds.
const PAGESIZE = 4096
const PAGESHIFT = (Int ∘ log2)(PAGESIZE)

#####
##### Initialization
#####

# Check if huge pages are enabled and display a warning if they are.
function __init__()
    check_hugepages()
end

#####
##### Extend "serialize" and "deserialize"
#####

###TODO: Future Julia release will not need these definitions
save(file::String, x) = open(f -> serialize(f, x), file, write = true)
load(file::String) = open(deserialize, file)

#####
##### File Includes
#####

include("hugepages.jl")
include("util.jl")
include("process.jl")
include("trace.jl")

# Measurements
include("measurements/measurements.jl")
include("analysis/analysis.jl")

# Plotting
include("plot.jl")

end # module
