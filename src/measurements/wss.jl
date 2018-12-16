"""
Record the Working Set Size (WSS) in bytes of an application using Idle Page Tracking.

This is essentially a wrapper for [`IdlePageTracker`], but just returns the working set
size rather than a trace of all active pages and thus is a better candidate for monitoring
long running programs.

If using an [`IdlePageTracker`](@ref), there is no need to use this measurement as well.
"""
struct WSS{T} <: AbstractMeasurement
    idlepage::IdlePageTracker{T}
end
WSS(f::Function = tautology) = WSS(IdlePageTracker(f))

function prepare(W::WSS, args...)
    # initialize the idle page tracker
    prepare(W.idlepage, args...) 
    return Vector{Int}()
end
measure(W::WSS, args...) = wss(measure(W.idlepage, args...))
