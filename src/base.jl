"""
    prepare(x, [kw])
"""
prepare(::Any) = nothing
prepare(x, kw) = prepare(x)

"""
    typehint(::Any)

Extend this function with the expected return type from `measure`.

Alternatively, you may extend [`allow_rettype`](@ref) to use the compiler's expected
return type for your measurement.
"""
typehint(::Any) = Any

# If the user has extended `typehint(x)` - return the result of that.
#
# Otherwise - the best we can do is `Any` anyways, so we might as well to invoke the
# compiler to get a return type.
#
# Since Tuples are covariant anyways, being looser with our type information will not be
# incorrect.
_typehint(x::Any, kw) = _typehint(typehint(x), x, kw)

function _typehint(::Any, x, kw)
    err = ArgumentError("SystemSnoop.typehint(::$(typeof(x))) must return a DataType")
    throw(err)
end
_typehint(::Type{T}, x, kw) where {T} = T
_typehint(::Type{Any}, x, kw) = Base.promote_op(measure, typeof(x), typeof(kw))


"""
    measure(x, [kw])

Perform a measurement for `x`. Argument `kw` is a `NamedTuple` of the keyword arguments
passed to [`snoop`](@ref).
"""
measure(::T) where {T} = error("Implement `measure` for $T")
measure(x, kw) = measure(x)

"""
    clean(x, [kw]) -> Nothing

Perform any cleanup needed by your measurement. This method is optional.
"""
clean(x, kw) = clean(x)
clean(::T) where {T} = nothing

