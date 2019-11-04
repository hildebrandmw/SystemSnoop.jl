## AbstractProcess ##
abstract type AbstractProcess end
pause(P::AbstractProcess) = pause(getpid(P))
resume(P::AbstractProcess) = resume(getpid(P))

abstract type AbstractPausable end
struct Unpausable <: AbstractPausable end
struct Pausable <: AbstractPausable end

struct GlobalProcess <: AbstractProcess end
pause(::GlobalProcess) = nothing
resume(::GlobalProcess) = nothing
getpid(::GlobalProcess) = 0
isrunning(::GlobalProcess) = true

"""
Struct container a `pid` as well as auxiliary data structure to make the snooping process
more efficient. `SnoopedProcess`es come in two variants, `Pausable` and `Unpausable`.

`Pausable` processes will be paused before a set of measurements are taken by calling
`kill -STOP` and resumed after afterwards by calling `kill -CONT`.
`Unpausable` processes will not be touched.

To construct a `Pausable` process with `pid`, call
```
ps = SnoopedProcess{Pausable}(pid)
```
To construct an `Unpausable` process, call
```
ps = SnoopedProcess{Unpausable}(pid)
```

Fields
------
* `pid::Int64` - The `pid` of the process.

Methods
-------
* `getpid` - Get the PID of this process.
* `isrunning` - Return `true` if process is running.
* [`prehook`](@ref) - Method to call before measurements.
* [`posthook`](@ref) - Method to call after measurements.
"""
struct SnoopedProcess{P <: AbstractPausable} <: AbstractProcess
    pid :: Int64
end

getpid(P::SnoopedProcess) = P.pid
isrunning(P::SnoopedProcess) = isrunning(getpid(P))
SnoopedProcess(pid::Integer) = SnoopedProcess{Unpausable}(pid)

# Before measurements
"""
    prehook(P::AbstractProcess)

If `P` is a pausable process, pause `P`.
"""
prehook(P::SnoopedProcess{Pausable}) = pause(P)
prehook(P::AbstractProcess) = nothing

# After measurements
"""
    posthook(P::AbstractProcess)

If `P` is a pausable process, unpause `P`.
"""
posthook(P::SnoopedProcess{Pausable}) = resume(P)
posthook(P::AbstractProcess) = nothing

