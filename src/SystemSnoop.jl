module SystemSnoop

export @snooped

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

function snooploop(x, milliseconds::Integer, canexit::Ref{Bool})
    return snooploop(x, Dates.Millisecond(milliseconds), canexit)
end

function snooploop(x, sleeptime::TimePeriod, canexit::Ref{Bool})
    return snooploop(x, SmartSample(sleeptime), canexit)
end

function snooploop(x, sampler, canexit::Ref{Bool})
    prepare(x)
    # Do the first measurement
    sleep(sampler)

    trace = container(x)
    push!(trace, measure(x))
    while !canexit[]
        sleep(sampler)
        push!(trace, measure(x))
    end
    clean(x)
    return trace
end

"""
    SystemSnoop.prepare(nt::NamedTuple) 

Call `SystemSnoop.prepare` on each element in `nt`.
"""
function prepare(nt::NamedTuple) 
    prepare.(Tuple(nt))
    return nothing
end

"""
    SystemSnoop.measure(nt::NamedTuple)::NamedTuple

Call `SystemSnoop.measure` on each element of `nt`.
The result is a `NamedTuple` with the same names as `nt`.
The values of the returned object are the result from calling `SystemSnoop.measure` on the
corresponding element of `nt`.
"""
measure(nt::NamedTuple{names}) where {names} = NamedTuple{names}(measure.(Tuple(nt)))

"""
    SystemSnoop.clean(nt::NamedTuple)::NamedTuple

Call `SystemSnoop.clean` on each element of `nt`.
"""
function clean(nt::NamedTuple) 
    clean.(Tuple(nt))
    return nothing
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
    trace = @snooped measurements::NamedTuple sampletime expr

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
    return quote
        canexit = Ref(false)
        task = @async snooploop($(esc(nt)), $(esc(sampler)), canexit)

        try
            # Splice in the expression.
            $(esc(expr))
        finally
            # Expression done, let the snooper know to finish up.
            canexit[] = true
        end

        fetch(task)
    end
end

end # module

