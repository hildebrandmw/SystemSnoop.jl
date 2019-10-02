"""
Collect timestamps.
"""
struct Timestamp end
prepare(::Timestamp, args...) = DateTime[]
measure(::Timestamp, args...) = now()

#####
##### snoop
#####

mutable struct Snooper{P <: AbstractProcess, NT <: NamedTuple, T}
    process::P
    measurements::NT
    trace::T

    # Flag to indicate if the cleanup routine has run.
    iscleaned::Bool

    # Inner constructor to attach finalizer
    function Snooper(process::P, measurements::NT) where {P, NT}
        trace = _prepare(process, measurements)
        snooper = new{P, NT, typeof(trace)}(process, measurements, trace, false)
        finalizer(clean, snooper)
        return snooper
    end
end


isrunning(S::Snooper) = isrunning(S.process)
function measure(S::Snooper)
    success = true
    try
        prehook(S.process)
        _measure(S.trace, S.measurements)
        posthook(S.process)
    catch error
        isa(error, PIDException) || rethrow(error)
        success = false
    end
    return success
end

function clean(S::Snooper)
    if !S.iscleaned
        _clean(S.measurements)
        S.iscleaned = true
    end
    return nothing
end

"""
    snoop(process, measurements::NamedTuple; kw...) -> NamedTuple

Perform a measurement trace on `process`. The measurements to be performed are specified
by the `measurements` argument. The values of this tuple are types that implement the
[`prepare`](@ref) and [`measure`](@ref) interface.

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
4. Call [`posthook`](@ref) on `process`
5. Repeat for each element of `iter`.

Measurements
------------
* `measurements::NamedTuple` : A `NamedTuple` where each element implements [`prepare`](@ref)
    and [`measure`](@ref).

Keyword Arguments
-----------------
* `sampletime` : Seconds between reading and reseting the idle page flags to determine page
    activity. Can also pass a [`SmartSample`](@ref) for better control of sample times. 
    Default: `2`

* `iter` : Iterator to control the number of samples to take. Default behavior is to keep
    sampling until monitored process terminates. Default: Run until program terminates.

Example
-------
Do five measurements of idle page tracking on the `top` command.

```
julia> measurements = (
    initial_timestamp = SystemSnoop.Timestamp(),
    idlepages = SystemSnoop.IdlePageTracker(),
    final_timestamp = SystemSnoop.Timestamp(),
);

julia> data = snoop(
    `top`,
    measurements;
    sampletime = 1,
    iter = 1:5
);

# Introspect into `data`
julia> typeof(data)
NamedTuple{(:initial_timestamp, :idlepages, :final_timestamp),Tuple{Array{Dates.DateTime,1},Array{Sample,1},Array{Dates.DateTime,1}}}
```

See also: [`SnoopedProcess`](@ref), [`SmartSample`](@ref)
"""
function snoop(f, process::AbstractProcess, measurements::NamedTuple)
    snooper = Snooper(process, measurements)
    f(snooper)
    return snooper.trace
end

function snoop(
        process::AbstractProcess, 
        measurements::NamedTuple; 
        sampletime = 2, 
        iter = Forever()
    )
    trace = snoop(process, measurements) do snooper
        for _ in iter
            sleep(sampletime)
            measure(snooper) || break
        end
    end
    return trace
end

snoop(pid::Integer, args...; kw...) = snoop(SnoopedProcess(pid), args...; kw...)
snoop(process::Base.Process, args...; kw...) = snoop(getpid(process), args...; kw...)
function snoop(cmd::Base.AbstractCmd, args...; kw...)
    local process
    try
        process = run(cmd; wait = false)
        return snoop(process, args...; kw...)
    finally
        kill(process)
    end
end

"""
    SystemSnoop.SmartSample(t::TimePeriod) -> SmartSample

Smart Sampler to ensure measurements happen every `t` time units. Samples will happen at
multiples of `t` from the first measurement. If a sample period is missed, the sampler will
wait until the next appropriate multiple of `t`.
"""
mutable struct SmartSample{T <: TimePeriod}
    initial::DateTime
    increment::T
    iteration::Int64
end

SmartSample(s::TimePeriod) = SmartSample(now(), s, 0)
function Base.sleep(s::SmartSample)
    # Initialize the sampler
    if s.iteration == 0
        s.initial = now()
        s.iteration = 1
    end

    # Compute the amount of time we need to sleep
    sleeptime = s.initial + (s.iteration * s.increment) - now()

    # Just incase measurements took longer than anticipated
    while sleeptime < zero(sleeptime)
        s.iteration += 1
        sleeptime = s.initial + (s.iteration * s.increment) - now()
    end
    sleep(sleeptime)
    s.iteration += 1
    return nothing
end

#####
##### Trace Kernel Functions
#####

# Tuple Magic :D
_first(m, args...) = m

## _prepare
function _prepare(process::AbstractProcess, measurements::NamedTuple{names}) where {names} 
    return NamedTuple{names}(_prepare(process, Tuple(measurements)...))
end
_prepare(process::AbstractProcess, m, args...) = (prepare(m, process), _prepare(process, args...)...)
_prepare(::AbstractProcess) = ()

## _measure
function _measure(trace::NamedTuple, measurements::NamedTuple) 
    _measure(Tuple(trace), Tuple(measurements))
    return nothing
end

function _measure(trace::Tuple, measurements::Tuple)
    t = _first(trace...)
    m = _first(measurements...)
    # Perform the first measurement
    push!(t, measure(m))
    # Recurse
    _measure(tail(trace), tail(measurements))
    return nothing
end
_measure(::Tuple{}, ::Tuple{}) = nothing

_clean(measurements::NamedTuple) = map(clean, Tuple(measurements))
