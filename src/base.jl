module SnoopBase

export  trace, 
        # Measurement API
        prepare, measure, clean,
        # Process Exports
        SnoopedProcess ,
        # Random utilities
        Forever, 
        Timeout,
        increment!, 
        PIDException, 
        pause, 
        resume,
        pidsafeopen,
        safeparse,
        isrunning,
        SmartSample,
        Timestamp

import Base: iterate, IteratorSize, IsInfinite, getpid, tail
using Dates

include("process.jl")
include("trace.jl")

"""
    prepare(M, P) -> Vector{T}

Return an empty vector to hold measurement data of type `T` for measurement `M`. Any 
initialization required `M` should happen here. Argument `P` is an object with a method

    getpid(P) -> Integer

Defined that returnd the PID of `P`.
"""
prepare(::T, args...) where {T} = error("Implement `prepare` for $T")

"""
    measure(M) -> T

Perform a measurement on `M` and return data of type `T`.
"""
measure(::T) where {T} = error("Implement `measure` for $T")

"""
    clean(M) -> Nothing

Performan any cleanup needed by your measurement. This method is optional.
"""
clean(::T) where {T} = nothing

#####
##### Utilities
#####

"""
In iterator that returns an infinite amount of `nothing`.
"""
struct Forever end

iterate(Forever, args...) = (nothing, nothing)
IteratorSize(::Forever) = IsInfinite()

"""
An iterator that stops iterating at a certain time.

**Example**
```
julia> using Dates

julia> y = SystemSnoop.Timeout(Second(10))
SystemSnoop.Timeout(2019-01-04T11:51:09.262)

julia> now()
2019-01-04T11:50:59.274

julia> for i in y; end

julia> now()
2019-01-04T11:51:09.275
```
"""
struct Timeout
    endtime::DateTime
end
Timeout(p::TimePeriod) = Timeout(now() + p)
iterate(T::Timeout, args...) = (now() >= T.endtime) ? nothing : (nothing, nothing)

"""
    increment!(d::AbstractDict, k, v)

Increment `d[k]` by `v`. If `d[k]` does not exist, initialize it to `v`.
"""
increment!(d::AbstractDict, k, v) = haskey(d, k) ? (d[k] += v) : (d[k] = v)

#####
##### Pagemap Utilities
#####

"""
Exception indicating that process with `pid` no longer exists.
"""
struct PIDException <: Exception 
    pid::Int64
end
PIDException() = PIDException(0)

#####
##### OS Utilities
#####

"""
    pause(pid)

Pause process with `pid`. If process does not exist, throw a [`PIDException`](@ref).
"""
function pause(pid) 
    try
        run(`kill -STOP $pid`)
    catch error
        isa(error, ErrorException) ? throw(PIDException(pid)) : rethrow(error)
    end
    return nothing
end

"""
    resume(pid)

Resume process with `pid`. If process does not exist, throw a [`PIDException`](@ref)
"""
function resume(pid)  
    try
        run(`kill -CONT $pid`)
    catch error
        isa(error, ErrorException) ? throw(PIDException(pid)) : rethrow(error)
    end
    return nothing
end

#####
##### PIDsafe macro
#####

"""
    pidfraceopen(f::Function, file::String, pid, args...; kw...)

Open system pseudo file `file` for process with `pid` and pass the handle to `f`. If a 
`File does not exist` error is thown, throws a `PIDException` instead.

Arguments `args` and `kw` are forwarded to the call to `open`.
"""
function pidsafeopen(f::Function, file::String, pid, args...; kw...)
    try
        open(file, args...; kw...) do handle
            f(handle)
        end
    catch error
        if isa(error, SystemError) && error.errnum == 2
            throw(PIDException(pid))
        else
            rethrow(error)
        end
    end
end

"""
    safeparse(::Type{T}, str; base = 10) -> T

Try to parse `str` to type `T`. If that fails, return `zero(T)`.
"""
function safeparse(::Type{T}, str; kw...) where {T}
    x = tryparse(T, str; kw...)
    return x === nothing ? zero(T) : x
end

"""
    isrunning(pid) -> Bool

Return `true` is a process with `pid` is running.
"""
isrunning(pid) = isdir("/proc/$pid")

end
