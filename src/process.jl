## AbstractProcess ##
abstract type AbstractProcess end
prehook(::AbstractProcess) = nothing
posthook(::AbstractProcess) = nothing

struct GlobalProcess <: AbstractProcess end
isrunning(::GlobalProcess) = true

struct Unpausable end
struct Pausable end

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
struct SnoopedProcess{P} <: AbstractProcess
    pid :: Int64
end

getpid(P::SnoopedProcess) = P.pid
isrunning(P::SnoopedProcess) = isrunning(getpid(P))
SnoopedProcess(pid::Integer) = SnoopedProcess{Unpausable}(pid)

pause(S::SnoopedProcess{Pausable}) = pause(getpid(S))
resume(S::SnoopedProcess{Pausable}) = resume(getpid(S))

# Before measurements
"""
    prehook(P::AbstractProcess)

If `P` is a pausable process, pause `P`.
"""
prehook(P::SnoopedProcess{Pausable}) = pause(P)

# After measurements
"""
    posthook(P::AbstractProcess)

If `P` is a pausable process, unpause `P`.
"""
posthook(P::SnoopedProcess{Pausable}) = resume(P)

