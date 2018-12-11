# And now we have a dependency on PAPI ...
using PAPI

# TODO: Right now, this only supports a single counter.
# extending to multiple counters should be easy though.
mutable struct PAPICounters{N} <: AbstractMeasurement
    codes::NTuple{N,Int32}
    names::NTuple{N,Symbol}

    eventset::PAPI.EventSet


    PAPICounters(name::Symbol, code::Int32) = new{1}((code,), (name,))
    function PAPICounters(names::NTuple{N,Symbol}, codes::NTuple{N,<:Integer}) where {N}
        new{N}(Int32.(codes), names)
    end
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

_rettype(P::PAPICounters{N}) where {N} = NamedTuple{P.names, NTuple{N, Int64}}

function prepare(P::PAPICounters)
    PAPI.start(P.eventset)
    return Vector{_rettype(P)}()
end

function measure(P::PAPICounters, process)
    # Stop/Read hardware counters and reset the counters.
    # calling "reset" automatically starts them counting again.
    PAPI.stop(P.eventset)
    PAPI.reset(P.eventset)
    counters = values(P.eventset)
    return (_rettype(P))(counters)
end
