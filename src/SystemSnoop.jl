module SystemSnoop

export @snooped, Timestamp, measure, prepare, clean, stopmeasuring, container

using Dates
import StructArrays: StructArray

#####
##### Sample periodically
#####

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

    # In case measurements took longer than anticipated
    while sleeptime < zero(sleeptime)
        s.iteration += 1
        sleeptime = s.initial + (s.iteration * s.increment) - now()
    end
    sleep(sleeptime)
    s.iteration += 1
    return nothing
end

#####
##### API
#####

struct StopMeasuringException <: Exception end
stopmeasuring() = throw(StopMeasuringException())

"""
    SystemSnoop.prepare(x)

This method is optional.
"""
prepare(::Any) = nothing

"""
    SystemSnoop.measure(x)

Perform a measurement for `x`.

This method is **required**.
"""
measure(x::T) where {T} = error("Implement `measure` for $T")

"""
    SystemSnoop.clean(x) -> Nothing

Perform any cleanup needed by your measurement. This method is optional.
"""
clean(::Any) = nothing

#####
##### Timestamp
#####

struct Timestamp end
measure(::Timestamp) = now()

#####
##### Snoop Loop
#####

function snooploop(x, milliseconds::Integer, kw::NamedTuple, canexit, firstsample)
    return snooploop(x, Dates.Millisecond(milliseconds), kw, canexit, firstsample)
end

function snooploop(x, sleeptime::TimePeriod, kw::NamedTuple, canexit, firstsample)
    return snooploop(x, SmartSample(sleeptime), kw, canexit, firstsample)
end

function snooploop(x, sampler, kw::NamedTuple, canexit, firstsample)
    prepare(x, kw)
    # Do the first measurement
    sleep(sampler)
    trace = container(x)
    try
        push!(trace, measure(x))
        firstsample[] = 1
        while canexit[] == 0
            sleep(sampler)
            push!(trace, measure(x))
        end
    catch e
        if !(e <: StopMeasuring)
            rethrow(e)
        end
    finally
        clean(x)
        firstsample[] = 1
    end
    return trace
end

argnames(x) = ()
vargnames(x) = Val(argnames(x))

_prepare(x, kw::NamedTuple) = _prepare(x, kw, vargnames(x))
_prepare(x, kw::NamedTuple, ::Val{Tuple{}}) = prepare(x)
@generated function _prepare(x, kw::NamedTuple, ::Val{names}) where {names}
    exprs = [:(kw.$name) for name in names]
    :(prepare(x, $(exprs...)))
end

"""
    SystemSnoop.prepare(nt::NamedTuple)

Call `SystemSnoop.prepare` on each element in `nt`.
"""
@generated function prepare(nt::NamedTuple{names}, kw::NamedTuple) where {names}
    exprs = [:(_prepare(nt.$name, kw)) for name in names]
    return quote
        $(exprs...)
        return nothing
    end
end

"""
    SystemSnoop.measure(nt::NamedTuple)::NamedTuple

Call `SystemSnoop.measure` on each element of `nt`.
The result is a `NamedTuple` with the same names as `nt`.
The values of the returned object are the result from calling `SystemSnoop.measure` on the
corresponding element of `nt`.
"""
@generated function measure(nt::NamedTuple{names}) where {names}
    exprs = [:(measure(nt.$name)) for name in names]
    return :(NamedTuple{names}(($(exprs...),)))
end

"""
    SystemSnoop.clean(nt::NamedTuple)::NamedTuple

Call `SystemSnoop.clean` on each element of `nt`.
"""
@generated function clean(nt::NamedTuple{names}) where {names}
    exprs = [:(clean(nt.$name)) for name in names]
    return quote
        $(exprs...)
        return nothing
    end
end

"""
    SystemSnoop.container(nt::NamedTuple)

Return an empty `StructArray` that can hold elements of type `measure(nt)`.
"""
container(nt::NamedTuple) = StructArray{Base.promote_op(measure, typeof(nt))}(undef, 0)
container(x::T) where {T} = Vector{Base.promote_op(measure, T)}(undef, 0)

#####
##### Macro
#####

"""
    trace = @snooped measurements::NamedTuple sampletime [kw] expr

Run execute `expr`. Every `sampletime` period (described below), take a measurement from the
`measurements` NamedTuple.

When `expr` finished execution, return all measurements taken as a `StructArray`.

Behavior of `sampletime`
* `sampletine::Int` -  Sample every `sampletime` milliseconds.
* `sampletime::Dates.TimePeriod` - Sample every `sampletime`.

Example
-------
```julia
juila> measurements = (
    timestamp_a = SystemSnoop.Timestamp(),
    timestamp_b = SystemSnoop.Timestamp(),
);

# Sample every 500 milliseconds
julia> trace = @snooped measurements 500 run(`sleep 5`)
6-element StructArray(::Array{Dates.DateTime,1}, ::Array{Dates.DateTime,1}) with eltype NamedTuple{(:timestamp_a, :timestamp_b),Tuple{Dates.DateTime,Dates.DateTime}}:
 (timestamp_a = 2020-06-25T10:25:19.706, timestamp_b = 2020-06-25T10:25:19.706)
 (timestamp_a = 2020-06-25T10:25:20.205, timestamp_b = 2020-06-25T10:25:20.205)
 (timestamp_a = 2020-06-25T10:25:20.706, timestamp_b = 2020-06-25T10:25:20.706)
 (timestamp_a = 2020-06-25T10:25:21.206, timestamp_b = 2020-06-25T10:25:21.206)
 (timestamp_a = 2020-06-25T10:25:21.705, timestamp_b = 2020-06-25T10:25:21.705)
 (timestamp_a = 2020-06-25T10:25:22.206, timestamp_b = 2020-06-25T10:25:22.206)

julia> propertynames(measurements) == propertynames(trace)
true
```
"""
macro snooped(nt, sampler, expr)
    return snooped_impl(nt, sampler, (;), expr)
end

macro snooped(nt, sampler, kw, expr)
    return snooped_impl(nt, sampler, kw, expr)
end


function snooped_impl(nt, sampler, kw, expr)
    return quote
        canexit = Threads.Atomic{Int}(0)
        firstsample = Threads.Atomic{Int}(1)
        task = @async snooploop($(esc(nt)), $(esc(sampler)), $(esc(kw)), canexit, firstsample)
        # Wait until the sampler begins sampling.
        while firstsample[] == 0
            sleep(0.001)
        end

        try
            # Splice in the expression.
            $(esc(expr))
        finally
            # Expression done, let the snooper know to finish up.
            canexit[] = 1
        end

        fetch(task)
    end
end

#####
##### CMD function
#####

function snoop(cmd::Base.AbstractCmd, sampler, measurements, kw = (;))
    trace = @snooped measurements sampler run(cmd; wait = true)
    return trace
end

end # module

