# The strategy here is to create a custom subtype of AbstractMeasurement
# to test that the internal functions of the "trace" function are being used.
mutable struct TestMeasure <: MemSnoop.AbstractMeasurement
    initialize::Int64
    prepare::Int64
    measure::Int64

    TestMeasure() = new(0,0,0)
end


MemSnoop.initialize!(T::TestMeasure, args...) = (T.initialize += 1; nothing)
MemSnoop.prepare(T::TestMeasure) = (T.prepare += 1; Int[])
MemSnoop.measure(T::TestMeasure, args...) = (T.measure += 1; T.measure)

@testset "Testing Trace Kernel Functions" begin

    process = MemSnoop.SnoopedProcess(getpid())

    #####
    ##### Testing a single Measurement
    #####

    T = TestMeasure()
    measurements = (T,)

    MemSnoop._initialize!(process, measurements...)
    @test T.initialize == 1

    trace = MemSnoop._prepare(measurements...)
    @test trace == (Int[],)
    @test T.prepare == 1

    MemSnoop._measure(process, trace, measurements)
    @test trace == ([1],)
    @test T.measure == 1

    #####
    ##### Testing 2 measurements
    #####

    T = TestMeasure()
    measurements = (T,T)

    MemSnoop._initialize!(process, measurements...)
    @test T.initialize == 2

    trace = MemSnoop._prepare(measurements...)
    @test trace == (Int[],Int[])
    @test T.prepare == 2

    MemSnoop._measure(process, trace, measurements)
    @test trace == ([1],[2])
    @test T.measure == 2

    ## Two DIFFERENT objects
    T = TestMeasure()
    S = TestMeasure()
    measurements = (T,S)
    MemSnoop._initialize!(process, measurements...)
    @test T.initialize == 1
    @test S.initialize == 1

    trace = MemSnoop._prepare(measurements...)
    @test trace == (Int[],Int[])
    @test T.prepare == 1
    @test S.prepare == 1

    MemSnoop._measure(process, trace, measurements)
    @test trace == ([1],[1])
    @test T.measure == 1
    @test S.measure == 1

    #####
    ##### Testing 2 measurements
    #####
    T = TestMeasure()
    measurements = (T,T,T)

    MemSnoop._initialize!(process, measurements...)
    @test T.initialize == 3

    trace = MemSnoop._prepare(measurements...)
    @test trace == (Int[], Int[], Int[])
    @test T.prepare == 3

    MemSnoop._measure(process, trace, measurements)
    @test trace == ([1], [2], [3])
    @test T.measure == 3
end

@testset "Testing Internal Calling" begin
    process = MemSnoop.SnoopedProcess(getpid())
    T = TestMeasure()
    measurements = (T,T)

    # Trace for 2 iterations
    data = trace(process, measurements; iter = 1:2)
    @test data == ([1,3],[2,4])
    @test T.initialize == 2
    @test T.prepare == 2
    @test T.measure == 4
end
