module SystemSnoop

using Dates

export trace, SnoopedProcess, Pausable, Unpausable

import Base: tail

#####
##### File Includes
#####

include("util.jl");     using .Utils
include("measure.jl");  using .Measurements

include("process.jl")
include("trace.jl")

# Measurements
include("measurements/measurements.jl")

end # module
