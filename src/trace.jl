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
    trace(process::AbstractProcess, measurements::Tuple; kw...) -> Tuple

Perform a measurement trace on `process`. The measurements to be performed are specified
by the `measurements` argument. Return a tuple `T` where `T[i]` is the data for
`measurements[i]`.

The general flow of this function is as follows:

1. Sleep for `sampletime`
2. Call [`prehook`](@ref) on `process`
3. Perform measurements
4. Call `callback`
5. Call [`posthook`](@ref) on `process`
6. Repeat for each element of `iter`.

Measurements
------------
* `measuremts::Tuple` : A tuple where each element is some [`AbstractMeasurement`](@ref).
    By default, the only measurement performed is [`IdlePageTracker`](@ref).

Keyword Arguments
-----------------
* `sampletime` : Seconds between reading and reseting the idle page flags to determine page
    activity. Default: `2`

* `iter` : Iterator to control the number of samples to take. Default behavior is to keep
    sampling until monitored process terminates. Default: Run until program terminates.

* `callback` : Optional callback for printing out status information (such as number 
    of iterations).
"""
function trace(
        process::AbstractProcess,
        names::Val = Val{(:idlepages,)},
        measurements::Tuple = (IdlePageTracker(tautology),); 
        sampletime = 2, 
        iter = Forever(), 
        callback = () -> nothing
    )

    _initialize!(process, measurements...)
    # Get a tuple of structs we are going to mutate
    trace = _prepare(names, measurements)

    try
        for i in iter
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

function _initialize!(process::AbstractProcess, m, args...) 
    # Initialize the first measurement
    initialize!(m, process)
    # Recurse
    _initialize!(process, args...) 
    return nothing
end
_initialize!(process::AbstractProcess) = nothing

# Tuple Magic
_first(m, args...) = m
_first() = ()

_prepare(names::Val{T}, measurements) where {T} = NamedTuple{T}(_prepare(measurements...))
_prepare(m, args...) = (prepare(m), _prepare(args...)...)
_prepare() = ()

_measure(process, trace::NamedTuple, measurements::Tuple) = _measure(process, Tuple(trace), measurements)

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

