# And now we have a dependency on PAPI ...
using PAPI

# TODO: Right now, this only supports a single counter.
# extending to multiple counters should be easy though.
mutable struct PAPICounters <: AbstractMeasurement
    codes::Vector{Int32}
    eventset::PAPI.EventSet

    PAPICounters(code::Int32) = new([code])
    PAPICounters(codes::Vector{Int32}) = new(codes)
end

function initialize!(P::PAPICounters, process)
    # Create a new eventset so we can run these back to back
    P.eventset = PAPI.EventSet()     
    PAPI.component!(P.eventset)

    # Attach to the PID
    PAPI.attach(P.eventset, getpid(process)) 
    for code in P.codes
        PAPI.addevent!(P.eventset, code)
    end

    return nothing
end

function prepare(P::PAPICounters)
    PAPI.start(P.eventset)
    return Vector{Int64}[]
end

function measure(P::PAPICounters, process)
    # Stop/Read hardware counters and reset the counters.
    # calling "reset" automatically starts them counting again.
    PAPI.stop(P.eventset)
    PAPI.reset(P.eventset)
    counters = values(P.eventset)

    return counters
end
