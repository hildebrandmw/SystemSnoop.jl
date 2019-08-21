module SystemSnoop

export  trace,
        # Measurement API
        prepare, measure, clean,
        # Process Exports
        SnoopedProcess,
        Pausable,
        Unpausable,
        # Random utilities
        Forever,
        Timeout,
        increment!,
        PIDException,
        pause,
        resume,
        pidsafeopen,
        safeparse,
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

end # module

