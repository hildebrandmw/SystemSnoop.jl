## AbstractProcess ##
abstract type AbstractProcess end
pause(P::AbstractProcess) = pause(getpid(P))
resume(P::AbstractProcess) = resume(getpid(P))

abstract type AbstractPausable end
struct Unpausable <: AbstractPausable end
struct Pausable <: AbstractPausable end

"""
Struct container a `pid` as well as auxiliary data structure to make the snooping process
more efficient.

Fields
------
* `pid::Int64` - The `pid` of the process.

Constructor
-----------
    SnoopedProcess(pid) -> SnoopedProcess

Construct a `Process` with the given `pid`.

Methods
-------
* `getpid` - Get the PID of this process.
* [`prehook`](@ref) - Method to call before measurements.
* [`posthook`](@ref) - Method to call after measurements.
"""
struct SnoopedProcess{P <: AbstractPausable} <: AbstractProcess
    pid :: Int64
end

Base.getpid(P::SnoopedProcess) = P.pid
SnoopedProcess(pid::Integer) = SnoopedProcess{Unpausable}(pid)

# Before measurements
"""
    prehook(P::AbstractProcess)

If `P` is a pausable process, pause `P`.
"""
prehook(P::SnoopedProcess{Pausable}) = pause(P)
prehook(P::SnoopedProcess{Unpausable}) = nothing

# After measurements
"""
    posthook(P::AbstractProcess)

If `P` is a pausable process, unpause `P`.
"""
posthook(P::SnoopedProcess{Pausable}) = resume(P)
posthook(P::SnoopedProcess{Unpausable}) = nothing

