# Testing of some base SystemSnoop stuff
mutable struct TestA{T <: Integer}
    prepare_count::T
    measure_count::T
end
TestA(::Type{T}) where {T} = TestA(zero(T), zero(T))

# Here, we check that at least some portion of the compilation pipeline is inferring
# correctly
SystemSnoop.prepare(x::TestA{T}, kw) where {T} = x.prepare_count += one(T)
function SystemSnoop.measure(x::TestA, kw)
    x.measure_count += 1
    return x.measure_count
end
SystemSnoop.allow_rettype(::TestA) = Val{true}()

@testset "Testing Some Stuff" begin
    measurements = (
        timestamp = SystemSnoop.Timestamp(),
        test_a = TestA(Int32),
    )

    snooper = SystemSnoop.Snooper(measurements)

    # Kinda nasty, but okay
    @test eltype(snooper.trace) == NamedTuple{(:timestamp, :test_a),Tuple{Dates.DateTime,Int32}}
    measure!(snooper)
    @test length(snooper.trace) == 1
end

