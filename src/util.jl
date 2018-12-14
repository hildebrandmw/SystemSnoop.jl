############################################################################################

"""
In iterator that returns an infinite amount of `nothing`.
"""
struct Forever end

iterate(Forever, args...) = (nothing, nothing)
IteratorSize(::Forever) = IsInfinite()

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
