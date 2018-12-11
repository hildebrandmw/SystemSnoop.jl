#####
##### AbstractMeasurement
#####

"""
Abstract supertype for process measurements.

Required API
------------
* [`prepare`](@ref)
* [`measure`](@ref)

Optional API
------------
* [`initialize!`](@ref)

Concrete Implementations
------------------------
* [`Timestamp`](@ref)
* [`IdlePageTracker`](@ref)
"""
abstract type AbstractMeasurement end

"""
    initialize!(M::AbstractMeasurement, process::AbstractProcess)

Perform any initialization required for measurement `M`. This method is optional and
defaults to a no-op.
"""
initialize!(::AbstractMeasurement, args...) = nothing

"""
    prepare(M::AbstractMeasurement) -> Vector{T}

Return an empty vector to hold measurement data of type `T` for measurement `M`.
"""
prepare(::T) where {T <: AbstractMeasurement} = error("Implement `prepare` for $T")

"""
    measure(M::AbstractMeasurement, process::AbstractProcess) -> T

Return data of type `T`.
"""
measure(::T, args...) where {T <: AbstractMeasurement} = error("Implement `measure` for $T")

## Time Stamping

"""
Collect timestamps.
"""
struct Timestamp <: AbstractMeasurement end
prepare(::Timestamp) = DateTime[]
measure(::Timestamp, args...) = now()

#####
##### trace
#####

"""
    trace(process::AbstractProcess, measurements::NamedTuple; kw...) -> NamedTuple

Perform a measurement trace on `process`. The measurements to be performed are specified
by the `measurements` argument. Return a `NamedTuple `T` with the same names as
`measurements` but whose values are the measurement data.

The general flow of this function is as follows:

1. Sleep for `sampletime`
2. Call [`prehook`](@ref) on `process`
3. Call [`measure`](@ref) on each measurement.
4. Call `callback`
5. Call [`posthook`](@ref) on `process`
6. Repeat for each element of `iter`.

Measurements
------------
* `measuremts::NamedTuple` : A `NamedTuple` where each element is some
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
Do five measurements of idle page tracking on the julia process itself.

```julia
julia> process = MemSnoop.SnoopedProcess(getpid())
MemSnoop.SnoopedProcess{MemSnoop.Unpausable}(15703)

julia> measurements = (
    initial_timestamp = MemSnoop.Timestamp(),
    idlepages = MemSnoop.IdlePageTracker(),
    final_timestamp = MemSnoop.Timestamp(),
);

julia> data = trace(
    process,
    measurements;
    sampletime = 1,
    iter = 1:5
);

# Introspect into `data`
julia> typeof(data)
NamedTuple{(:initial_timestamp, :idlepages, :final_timestamp),Tuple{Array{Dates.DateTime,1},Array{Sample,1},Array{Dates.DateTime,1}}}
```
"""
function trace(
        process::AbstractProcess,
        measurements::NamedTuple{S,<:NTuple{N,AbstractMeasurement}};
        sampletime = 2,
        iter = Forever(),
        callback = () -> nothing
    ) where {S,N}

    _initialize!(process, measurements)
    # Get a tuple of structs we are going to mutate
    trace = _prepare(measurements)

    try
        for i in iter
            sampletime
            sleep(sampletime)

            ## Prep for taking measurements
            prehook(process)
            data = _measure(process, trace, measurements)

            ## Cleanup after measurements
            callback()
            posthook(process)
        end
    catch error
        isa(error, PIDException) || rethrow(error)
    end
    return trace
end
trace(process::AbstractProcess, names::Tuple, args...; kw...) = trace(process, Val(names), args...; kw...)

#####
##### Trace Kernel Functions
#####

# Tuple Magic
_first(m, args...) = m
_first() = ()

#=
The general strategy to these function is to leverage julia's type inference and
specialization to statically resolve all of the funtions calls instead of needing to do
dynamic dispatch. That is why some of these function calls look unnecessarily complicated -
it's because Julia's compilier is good at figuring this stuff out.
=#
_initialize!(process::AbstractProcess, measurements::NamedTuple) = _initialize!(process, Tuple(measurements)...)
function _initialize!(process::AbstractProcess, m, args...)
    # Initialize the first measurement
    initialize!(m, process)
    # Recurse
    _initialize!(process, args...)
    return nothing
end
_initialize!(process::AbstractProcess) = nothing

_prepare(measurements::NamedTuple{names}) where {names} = NamedTuple{names}(_prepare(Tuple(measurements)...))
_prepare(m, args...) = (prepare(m), _prepare(args...)...)
_prepare() = ()

_measure(process, trace::NamedTuple, measurements::NamedTuple) = _measure(process, Tuple(trace), Tuple(measurements))
function _measure(process, trace::Tuple, measurements::Tuple)
    t = _first(trace...)
    m = _first(measurements...)
    # Perform the first measurement
    push!(t, measure(m, process))
    # Recurse
    _measure(process, tail(trace), tail(measurements))
    return nothing
end
_measure(process, trace::Tuple{}, measurements::Tuple{}) = nothing

