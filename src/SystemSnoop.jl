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
    prepare(x)

This method is optional.
"""
prepare(::Any) = nothing

"""
    measure(x)

Perform a measurement for `x`.

This method is required.
"""
measure(x::T) where {T} = error("Implement `measure` for $T")

"""
    clean(x) -> Nothing

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

function snooploop(nt::NamedTuple, milliseconds::Integer, canexit::Ref{Bool})
    return snooploop(nt, Dates.Millisecond(milliseconds), canexit)
end

function snooploop(nt::NamedTuple, sleeptime::TimePeriod, canexit::Ref{Bool})
    return snooploop(nt, SmartSample(sleeptime), canexit)
end

function snooploop(nt::NamedTuple, sampler, canexit::Ref{Bool})
    prepare(nt)
    # Do the first measurement
    sleep(sampler)
    trace = StructArray([measure(nt)])
    while !canexit[]
        sleep(sampler)
        push!(trace, measure(nt))
    end
    clean(nt)
    return trace
end

prepare(nt::NamedTuple) = prepare.(Tuple(nt))
measure(nt::NamedTuple{names}) where {names} = NamedTuple{names}(measure.(Tuple(nt)))
clean(nt::NamedTuple) = clean.(Tuple(nt))

container(nt::NamedTuple) = StructArray{Base.promote_op(measure, typeof(nt))}(undef, 0)

#####
##### Macro
#####

macro snooped(nt, sampler, expr)
    return quote
        canexit = Ref(false)
        task = @async snooploop($(esc(nt)), $(esc(sampler)), canexit)

        # Splice in the expression.
        $(esc(expr))

        # Expression done, let the snooper know to finish up.
        canexit[] = true
        fetch(task)
    end
end

end # module

