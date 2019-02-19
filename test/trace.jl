# The strategy here is to create a custom type to test that the internal functions of the 
# "trace" function are being used.
mutable struct TestMeasure
    prepare::Int64
    measure::Int64

    TestMeasure() = new(0,0)
end

SystemSnoop.SnoopBase.prepare(T::TestMeasure, args...) = (T.prepare += 1; Int[])
SystemSnoop.SnoopBase.measure(T::TestMeasure, args...) = (T.measure += 1; T.measure)

@testset "Testing Trace Kernel Functions" begin

    process = SystemSnoop.SnoopedProcess(getpid())

    #####
    ##### Testing a single Measurement
    #####

    T = TestMeasure()
    measurements = (test = T,)

    trace = SystemSnoop.SnoopBase._prepare(process, measurements)
    @test trace == (test = Int[],)
    @test T.prepare == 1

    SystemSnoop.SnoopBase.SnoopBase._measure(trace, measurements)
    @test trace == (test = [1],)
    @test T.measure == 1

    #####
    ##### Testing 2 measurements
    #####

    T = TestMeasure()
    measurements = (testA = T ,testB = T)

    trace = SystemSnoop.SnoopBase._prepare(process, measurements)
    @test trace == (testA = Int[], testB = Int[])
    @test T.prepare == 2

    SystemSnoop.SnoopBase._measure(trace, measurements)
    @test trace == (testA = [1], testB = [2])
    @test T.measure == 2

    ## Two DIFFERENT objects
    T = TestMeasure()
    S = TestMeasure()
    measurements = (testT = T, testS = S)

    trace = SystemSnoop.SnoopBase._prepare(process, measurements)
    @test trace == (testT = Int[], testS = Int[])
    @test T.prepare == 1
    @test S.prepare == 1

    SystemSnoop.SnoopBase._measure(trace, measurements)
    @test trace == (testT = [1], testS = [1])
    @test T.measure == 1
    @test S.measure == 1

    #####
    ##### Testing 3 measurements
    #####
    T = TestMeasure()
    measurements = (A = T, B = T, C = T)

    trace = SystemSnoop.SnoopBase._prepare(process, measurements)
    @test trace == (A = Int[], B = Int[], C = Int[])
    @test T.prepare == 3

    SystemSnoop.SnoopBase._measure(trace, measurements)
    @test trace == (A = [1], B = [2], C = [3])
    @test T.measure == 3
end

@testset "Testing Internal Calling" begin
    process = SystemSnoop.SnoopedProcess(getpid())
    T = TestMeasure()
    measurements = (A = T, B = T)

    # Trace for 2 iterations
    data = trace(process, measurements; iter = 1:2)
    @test data == (A = [1,3], B = [2,4])
    @test T.prepare == 2
    @test T.measure == 4
end
