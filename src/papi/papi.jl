# And now we have a dependency on PAPI ...
using PAPI

# TODO: Right now, this only supports a single counter.
# extending to multiple counters should be easy though.
mutable struct PAPICounters <: AbstractMeasurement
    code::Int32
    eventset::PAPI.EventSet

    PAPICounters(code) = new(code)
end

function initialize!(P::PAPICounters, process)
    # Create a new eventset so we can run these back to back
    P.eventset = PAPI.EventSet()     
    PAPI.component!(P.eventset)

    # Attach to the PID
    PAPI.attach(P.eventset, getpid(process)) 
    PAPI.addevent!(P.eventset, P.code)

    return nothing
end

function prepare(P::PAPICounters)
    PAPI.start(P.eventset)
    return Int[]
end

function measure(P::PAPICounters, process)
    # Read hardware counters
    PAPI.read(P.eventset)
    PAPI.reset(P.eventset)
    counters = values(P.eventset)
    
    return first(counters)
end
