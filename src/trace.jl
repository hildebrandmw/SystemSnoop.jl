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

        trace = StructArrays.StructArray{trace_eltype}(undef, 0)

        _prepare(measurements, kw)
        snooper = new{NamedTuple{names,types}, N, P, typeof(trace)}(
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

# Call `postprocess` on each of the measurements, gathering only the non-empty results
function postprocess(S::Snooper)
    # Temporarily strip the `StructArrays` semantics from the NamedTuple so we can do some
    # tuple tricks with it.
    arrays = StructArrays.fieldarrays(S.trace)

    # Call `process` on the measurement - trace pairs.
    processed_data = postprocess.(Tuple(S.measurements), Tuple(arrays), Ref(S.kw))
    return merge(processed_data...)
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

maybewrap(x, ::Nothing) = x
maybewrap(x, y) = (x, y)

"""
    snoop(f, measurements::NamedTuple, [process = GlobalProcess()]) -> StructArray
"""
function snoop(f, measurements::NamedTuple, process::AbstractProcess = GlobalProcess(); kw...)
    snooper = Snooper(measurements, process; kw...)
    val = f(snooper)
    clean(snooper)

    # Capture the returned value from the inner function.
    # If they wanted to return something, wrap it up with the trace for them.
    #
    # This provides a nice API for explicitly performing post-processing
    return maybewrap(snooper.trace, val)
end

# Specilizations for some stuff
snoop(f, x, pid::Integer; kw...) = snoop(f, x, SnoopedProcess(pid); pid = pid, kw...)
snoop(f, x, process::Base.Process; kw...) = snoop(f, x, getpid(process); kw...)
function snoop(f, measurements::NamedTuple, cmd::Base.AbstractCmd; kw...)
    local process
    try
        # Launch a process
        process = run(cmd; wait = false)

        # Send it up the dispatch chain!
        return snoop(f, measurements, process; kw...)
    finally
        kill(process)
    end
end

