############################################################################################

"""
In iterator that returns an infinite amount of `nothing`.
"""
struct Forever end

iterate(Forever, args...) = (nothing, nothing)
IteratorSize(::Forever) = IsInfinite()

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
