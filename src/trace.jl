"""
Collect timestamps.
"""
struct Timestamp end
Measurements.prepare(::Timestamp, args...) = DateTime[]
Measurements.measure(::Timestamp, args...) = now()

#####
##### trace
#####

"""
    trace(process, measurements::NamedTuple; kw...) -> NamedTuple

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
4. Call `callback`
5. Call [`posthook`](@ref) on `process`
6. Repeat for each element of `iter`.

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

* `callback` : Optional callback for printing out status information (such as number
    of iterations).

Example
-------
Do five measurements of idle page tracking on the `top` command.

```
julia> measurements = (
    initial_timestamp = SystemSnoop.Timestamp(),
    idlepages = SystemSnoop.IdlePageTracker(),
    final_timestamp = SystemSnoop.Timestamp(),
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

See also: [`SnoopedProcess`](@ref), [`SmartSample`](@ref)
"""
function trace(
        process::AbstractProcess,
        measurements::NamedTuple;
        sampletime = 2,
        iter = Forever(),
        callback = (args...) -> nothing
    )

    # Get a tuple of structs we are going to mutate
    trace = _prepare(process, measurements)
    try
        for _ in iter
            ## Wait for next iteration
            _sleep(sampletime)

            # Abort if process is no longer running
            isrunning(process) || break

            ## Prep for taking measurements
            prehook(process)
            _measure(trace, measurements)

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
    try
        process = run(cmd; wait = false)
        return trace(process, args...; kw...)
    finally
        kill(process)
    end
end

#####
##### _sleep
#####

_sleep(x::Number) = sleep(x)

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
function _sleep(s::SmartSample)
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
_prepare(process::AbstractProcess, m, args...) = (Measurements.prepare(m, process), _prepare(process, args...)...)
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
    push!(t, Measurements.measure(m))
    # Recurse
    _measure(tail(trace), tail(measurements))
    return nothing
end
_measure(::Tuple{}, ::Tuple{}) = nothing
