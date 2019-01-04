#####
##### AbstractMeasurement
#####

"""
Abstract supertype for process measurements.

Required API
------------
* [`prepare`](@ref)
* [`measure`](@ref)

Concrete Implementations
------------------------
* [`Timestamp`](@ref)
* [`IdlePageTracker`](@ref)
* [`DiskIO`](@ref)
* [`Statm`](@ref)
"""
abstract type AbstractMeasurement end

"""
    prepare(M::AbstractMeasurement, P::AbstractProcess) -> Vector{T}

Return an empty vector to hold measurement data of type `T` for measurement `M`. Any 
initialization required `M` should happen here.
"""
prepare(::T, args...) where {T <: AbstractMeasurement} = error("Implement `prepare` for $T")

"""
    measure(M::AbstractMeasurement, P::AbstractProcess) -> T

Return data of type `T`.
"""
measure(::T, args...) where {T <: AbstractMeasurement} = error("Implement `measure` for $T")

## Time Stamping

"""
Collect timestamps.
"""
struct Timestamp <: AbstractMeasurement end
prepare(::Timestamp, args...) = DateTime[]
measure(::Timestamp, args...) = now()

#####
##### trace
#####

"""
    trace(process, measurements::NamedTuple; kw...) -> NamedTuple

Perform a measurement trace on `process`. The measurements to be performed are specified
by the `measurements` argument. The values of this tuple are [`AbstractMeasurement`](@ref)s.

Return a `NamedTuple` `T` with the same names as
`measurements` but whose values are the measurement data.

Argument `process` can be:

* A [`SnoopedProcess`](@ref)
* An integer representing a process PID
* A `Base.Process` spawned by Julia
* A `Cmd` that will launch a process


The general flow of this function is as follows:

1. Sleep for `sampletime`
2. Call [`prehook`](@ref) on `process`
3. Call [`measure`](@ref) on each measurement.
4. Call `callback`
5. Call [`posthook`](@ref) on `process`
6. Repeat for each element of `iter`.

Measurements
------------
* `measurements::NamedTuple` : A `NamedTuple` where each element is some
    [`AbstractMeasurement`](@ref).

Keyword Arguments
-----------------
* `sampletime` : Seconds between reading and reseting the idle page flags to determine page
    activity. Default: `2`

* `iter` : Iterator to control the number of samples to take. Default behavior is to keep
    sampling until monitored process terminates. Default: Run until program terminates.

* `callback` : Optional callback for printing out status information (such as number
    of iterations).

Example
-------
Do five measurements of idle page tracking on the `top` command.

```
julia> measurements = (
    initial_timestamp = MemSnoop.Timestamp(),
    idlepages = MemSnoop.IdlePageTracker(),
    final_timestamp = MemSnoop.Timestamp(),
);

julia> data = trace(
    `top`,
    measurements;
    sampletime = 1,
    iter = 1:5
);

# Introspect into `data`
julia> typeof(data)
NamedTuple{(:initial_timestamp, :idlepages, :final_timestamp),Tuple{Array{Dates.DateTime,1},Array{Sample,1},Array{Dates.DateTime,1}}}
```

See also: [`AbstractMeasurement`](@ref), [`SnoopedProcess`](@ref)
"""
function trace(
        process::AbstractProcess,
        measurements::NamedTuple{S,<:NTuple{N,AbstractMeasurement}};
        sampletime = 2,
        iter = Forever(),
        callback = (args...) -> nothing
    ) where {S,N}

    # Get a tuple of structs we are going to mutate
    trace = _prepare(process, measurements)
    try
        for _ in iter
            # Abort if process is no longer running
            isrunning(process) || break
            sleep(sampletime)

            ## Prep for taking measurements
            prehook(process)
            _measure(process, trace, measurements)

            ## Cleanup after measurements
            callback(process, trace, measurements)
            posthook(process)
        end
    catch error
        isa(error, PIDException) || rethrow(error)
    end
    return trace
end

trace(pid::Integer, args...; kw...) = trace(SnoopedProcess(pid), args...; kw...)
trace(process::Base.Process, args...; kw...) = trace(getpid(process), args...; kw...)
function trace(cmd::Base.AbstractCmd, args...; kw...)
    process = run(cmd; wait = false)
    return trace(process, args...; kw...)
end

#####
##### Trace Kernel Functions
#####

# Tuple Magic
_first(m, args...) = m

#=
The general strategy to these function is to leverage julia's type inference and
specialization to statically resolve all of the funtions calls instead of needing to do
dynamic dispatch. That is why some of these function calls look unnecessarily complicated -
it's because Julia's compilier is good at figuring this stuff out.
=#

## _prepare
function _prepare(process::AbstractProcess, measurements::NamedTuple{names}) where {names} 
    return NamedTuple{names}(_prepare(process, Tuple(measurements)...))
end
_prepare(process::AbstractProcess, m, args...) = (prepare(m, process), _prepare(process, args...)...)
_prepare(::AbstractProcess) = ()

## _measure
function _measure(process::AbstractProcess, trace::NamedTuple, measurements::NamedTuple) 
    _measure(process, Tuple(trace), Tuple(measurements))
    return nothing
end

function _measure(process, trace::Tuple, measurements::Tuple)
    t = _first(trace...)
    m = _first(measurements...)
    # Perform the first measurement
    push!(t, measure(m, process))
    # Recurse
    _measure(process, tail(trace), tail(measurements))
    return nothing
end
_measure(process, ::Tuple{}, ::Tuple{}) = nothing

