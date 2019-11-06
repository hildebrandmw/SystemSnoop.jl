"""
Collect timestamps.
"""
struct Timestamp end
measure(::Timestamp, kw) = now()
typehint(::Timestamp) = DateTime

#####
##### snoop
#####

mutable struct Snooper{NT <: NamedTuple, A <: NamedTuple, P <: AbstractProcess, T}
    measurements::NT
    kw::A
    process::P
    trace::T

    # Flag to indicate if the cleanup routine has run.
    iscleaned::Bool

    # Inner constructor to attach finalizer
    function Snooper(measurements::NamedTuple{names,types}, process::P, kw::N) where {names, types, P, N <: NamedTuple}
        # Determine the container type for results.
        trace_eltype = NamedTuple{
            names,
            Tuple{_typehint.(Tuple(measurements), Ref(kw))...}
        }
        trace = Vector{trace_eltype}()

        _prepare(measurements, kw)
        snooper = new{NamedTuple{names,types}, N, P, Vector{trace_eltype}}(
            measurements,
            kw,
            process,
            trace,
            false
        )

        finalizer(clean, snooper)
        return snooper
    end
end

# Forward keyword arguments to a NamedTuple.
function Snooper(measurements::NamedTuple, process::AbstractProcess = GlobalProcess(); kw...)
    return Snooper(measurements, process, (;kw...))
end

function measure!(S::Snooper)
    prehook(S.process)
    push!(S.trace, _measure(S.measurements, S.kw))
    posthook(S.process)
    return nothing
end

function clean(S::Snooper)
    if !S.iscleaned
        _clean(S.measurements)
        S.iscleaned = true
    end
    return nothing
end

# Broadcasting inner methods
_prepare(measurements::NamedTuple, kw) = prepare.(Tuple(measurements), Ref(kw))

function _measure(ms::NamedTuple{names}, kw) where {names}
    return NamedTuple{names}(measure.(Tuple(ms), Ref(kw)))
end

_clean(measurements::NamedTuple) = map(clean, Tuple(measurements))

# Forwards
isrunning(S::Snooper) = isrunning(S.process)

#####
##### `snoop`
#####

snoop(f, measurements::NamedTuple; kw...) = snoop(f, GlobalProcess(), measurements; kw...)
function snoop(f, process::AbstractProcess, measurements::NamedTuple; kw...)
    snooper = Snooper(measurements, process; kw...)
    f(snooper)
    clean(snooper)
    return snooper.trace
end

# Specilizations for some stuff
snoop(f, pid::Integer, x...; kw...) = snoop(f, SnoopedProcess(pid), x...; pid = pid, kw...)
snoop(f, process::Base.Process, x...; kw...) = snoop(f, getpid(process), x...; kw...)
function snoop(f, cmd::Base.AbstractCmd, measurements::NamedTuple; kw...)
    local process
    try
        # Launch a process
        process = run(cmd; wait = false)

        # Send it up the dispatch chain!
        return snoop(f, process, measurements; kw...)
    finally
        kill(process)
    end
end

