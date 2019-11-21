"""
    prepare(x, [kw::NamedTuple])

Perform any preparation steps required for measurement type `x`.

If no external arguments are required, you can simply extend
```julia
SystemSnoop.prepare(x)
```
for `typeof(x)`.

Otherwise, you will recieve a named tuple `kw` corresponding to the keyword arguments
passed to the enclosing call to [`snoop`](@ref).

This method is optional.
"""
prepare(::Any) = nothing
prepare(x, kw) = prepare(x)

# Use `Sentinel` for dispatch purposes.
struct Sentinel end

"""
    typehint(::Any)

Extend this function with the expected return type from `measure`.
If this method is not defined, SystemSnoop will fallback on Julia's type inference.

This method is optional.
"""
typehint(::Any) = Sentinel

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
@inline _typehint(::Type{T}, x, kw) where {T} = T
@inline _typehint(::Type{Sentinel}, x, kw) = Base.promote_op(measure, typeof(x), typeof(kw))

"""
    measure(x, [kw])

Perform a measurement for `x`. Optional argument `kw` is a `NamedTuple` of the keyword
arguments passed to [`snoop`](@ref).

This method is required.
"""
measure(x::T) where {T} = error("Implement `measure` for $T")
measure(x, kw) = measure(x)

"""
    clean(x, [kw]) -> Nothing

Perform any cleanup needed by your measurement. This method is optional.
"""
clean(x, kw) = clean(x)
clean(::Any) = nothing

"""
    postprocess(x, v, [kw]) -> NamedTuple

Perform any post-processing for the measured data `v` from measurement `x`.

* If a `NamedTuple` is returned, the names from the tuple will be inlined into the collected
data.
"""
postprocess(x, v, kw) = postprocess(x, v)
postprocess(x, v) = NamedTuple()


