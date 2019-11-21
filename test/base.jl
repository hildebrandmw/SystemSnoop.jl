@testset "Testing Base" begin
    # Don't declare a typehint - see if  inference works correctly.
    struct Test1 end
    SystemSnoop.measure(::Test1, kw) = 1
    @test SystemSnoop._typehint(Test1(), NamedTuple()) == Int

    # Now, manually construct a typehint and make sure that works
    struct Test2 end
    SystemSnoop.typehint(::Test2) = Int
    @test SystemSnoop._typehint(Test2(), NamedTuple()) == Int

    # Make sure we get an error if `typehint` is extended incorrectly.
    struct Test3 end
    SystemSnoop.typehint(::Test3) = 1
    @test_throws ArgumentError SystemSnoop._typehint(Test3(), NamedTuple())
end

# Testing of some base SystemSnoop stuff
mutable struct TestA{T <: Integer}
    num::Int
    prepare_count::T
    measure_count::T
    clean_count::T
end
TestA(::Type{T}; num = 1) where {T} = TestA(num, zero(T), zero(T), zero(T))

# Here, we check that at least some portion of the compilation pipeline is inferring
# correctly
SystemSnoop.prepare(x::TestA{T}, kw) where {T} = x.prepare_count += one(T)
function SystemSnoop.measure(x::TestA, kw)
    x.measure_count += 1
    return x.measure_count
end
SystemSnoop.clean(x::TestA) = (x.clean_count += 1)
SystemSnoop.postproces(x::TestA, v) = (Symbol("x$(x.num)") = "it works!",)

_tupletype(::Type{NamedTuple{N,T}}) where {N,T} = T
_keys(::Type{NamedTuple{N,T}}) where {N,T} = N

@testset "Testing API Functions and Snooper" begin
    measurements = (
        timestamp = SystemSnoop.Timestamp(),
        test_a = TestA(Int32; num = 1),
        test_b = TestA(Int32; num = 2),
    )

    # All fields should begin at zero
    tester = measurements.test_a
    @test tester.prepare_count == 0
    @test tester.measure_count == 0
    @test tester.clean_count == 0

    # Create the Snooper
    snooper = SystemSnoop.Snooper(measurements)

    # This should default to the GlobalProcess - make sure `isrunning` returns true
    @test isrunning(snooper) == true

    # Check that inference worked correctly, even though we didn't specify `typehints`
    @test _keys(eltype(snooper.trace)) == (:timestamp, :test_a, :test_b)
    @test _tupletype(eltype(snooper.trace)) == Tuple{Dates.DateTime,Int32,Int32}

    measure!(snooper)
    @test length(snooper.trace) == 1

    @test tester.prepare_count == 1
    @test tester.measure_count == 1
    @test tester.clean_count == 0

    measure!(snooper)
    @test tester.prepare_count == 1
    @test tester.measure_count == 2
    @test tester.clean_count == 0

    SystemSnoop.clean(snooper)
    @test tester.prepare_count == 1
    @test tester.measure_count == 2
    @test tester.clean_count == 1

    # Make sure calling `clean` again doesn't do something strange.
    SystemSnoop.clean(snooper)
    @test tester.clean_count == 1

    # Make sure that results matches for the other tester.
    tester_b = measurements.test_b
    @test tester_b.prepare_count == 1
    @test tester_b.measure_count == 2
    @test tester_b.clean_count == 1

    # Now, we check that inference works correctly.
    @inferred SystemSnoop._prepare(measurements, NamedTuple())
    @inferred SystemSnoop._measure(measurements, NamedTuple())
    @inferred SystemSnoop._clean(measurements)

    # Now make sure `postprocess` works.
    processed = SystemSnoop.postprocess(snooper)
    @test processed == (:x1 = "it works!", :x2 = "it works!")
end

