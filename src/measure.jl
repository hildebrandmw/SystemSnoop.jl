module Measurements

export prepare, measure

"""
    prepare(M::AbstractMeasurement, P) -> Vector{T}

Return an empty vector to hold measurement data of type `T` for measurement `M`. Any 
initialization required `M` should happen here. Argument `P` is an object with a method

    getpid(P) -> Integer

Defined that returnd the PID of `P`.
"""
prepare(::T, args...) where {T} = error("Implement `prepare` for $T")

"""
    measure(M::AbstractMeasurement) -> T

Perform a measurement on `M` and return data of type `T`.
"""
measure(::T) where {T} = error("Implement `measure` for $T")


end
