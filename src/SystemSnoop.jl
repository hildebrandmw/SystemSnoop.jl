module SystemSnoop

export  snoop,
        # Measurement API
        measure!,
        # Process Exports
        SnoopedProcess,
        Pausable,
        Unpausable,
        # Random utilities
        Forever,
        Timeout,
        PIDException,
        pause,
        resume,
        isrunning,
        SmartSample,
        Timestamp

import Base: iterate, IteratorSize, IsInfinite, getpid, tail
using Dates

#####
##### File Includes
#####

include("process.jl")
include("trace.jl")
include("base.jl")
include("utils.jl")

end # module

