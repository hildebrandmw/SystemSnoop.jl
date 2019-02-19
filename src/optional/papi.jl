module PAPI

export PAPICounters

import ..SnoopBase
using ..PAPI

mutable struct PAPICounters{N, names}
    codes::NTuple{N,Int32}
    eventset::PAPI.EventSet

    # Constructers
    PAPICounters(name::Symbol, code::Int32) = new{1, (name,)}((code,))

    function PAPICounters(names::NTuple{N,Symbol}, codes::NTuple{N,<:Integer}) where {N}
        new{N, names}(Int32.(codes))
    end
end

_rettype(::PAPICounters{N,names}) where {N,names} = NamedTuple{names, NTuple{N, Int64}}
function SnoopBase.prepare(P::PAPICounters, process)
    # Create a new eventset so we can run these back to back
    P.eventset = PAPI.EventSet()     
    PAPI.component!(P.eventset)

    # Attach to the PID
    PAPI.attach(P.eventset, getpid(process)) 
    for code in P.codes
        PAPI.addevent!(P.eventset, code)
    end

    PAPI.start(P.eventset)
    return Vector{_rettype(P)}()
end

function SnoopBase.measure(P::PAPICounters)
    # Stop/Read hardware counters and reset the counters.
    # calling "reset" automatically starts them counting again.
    PAPI.stop(P.eventset)
    PAPI.reset(P.eventset)
    counters = values(P.eventset)
    return (_rettype(P))(counters)
end

end
