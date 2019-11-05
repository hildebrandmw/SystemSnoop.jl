"""
    prepare(x, kw)
"""
prepare(::T, kw) where {T} = nothing

"""
    allow_retype(x) -> Val{false}

By default, disables automatic checking of compiler return type for `measure(x, kw)` when
inferring storage. Instead, falls back to `typehint(x)`.

Extending this for your types to return `Val{true}()` will instead use
`Core.Compiler.return_type`.
"""
allow_rettype(::Any) = Val{false}()

"""
    typehint(::Any)

Extend this function with the expected return type from `measure`.

Alternatively, you may extend [`allow_rettype`](@ref) to use the compiler's expected
return type for your measurement.
"""
typehint(::Any) = Any

_typehint(x::Any, kw) = _typehint(allow_rettype(x), x, kw)
_typehint(::Val{false}, x, kw) = typehint(x)
_typehint(::Val{true}, x...) = Core.Compiler.return_type(measure, typeof.(x))

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

