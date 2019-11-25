# Test for some of the more complicated functionality.
mutable struct DummyProcess <: SystemSnoop.AbstractProcess
    prehook_count::Int
    posthook_count::Int
end

SystemSnoop.prehook(D::DummyProcess) = (D.prehook_count += 1)
SystemSnoop.posthook(D::DummyProcess) = (D.posthook_count += 1)

# Require that `kw` are forwarded
mutable struct Incrementer
    count::Int
end
function SystemSnoop.measure(x::Incrementer, kw)
    x.count += kw.increment
    return x.count
end

SystemSnoop.postprocess(x::Incrementer, v) = (incrementer = x.count,)

function inference_check()
    measurements = (
        timestamp = SystemSnoop.Timestamp(),
        incrementer = Incrementer(0),
    )
    iters = 5
    increment = 1
    return snoop(measurements; increment = increment) do snooper
        for _ in 1:iters
            sleep(0.01)
            measure!(snooper)
        end
        return SystemSnoop.postprocess(snooper)
    end
end

@testset "snoop" begin
    # Use the `TestA` code from base.jl
    measurements = (
        timestamp = SystemSnoop.Timestamp(),
        incrementer = Incrementer(0),
    )

    process = DummyProcess(0, 0)

    # Call the outer `snoop` function with our dummy process. Make sure everything runs
    # smoothly.
    iters = 3
    increment = 20
    trace = snoop(measurements, process; increment = increment) do snooper
        for _ in 1:iters
            measure!(snooper)
        end
    end

    # Inspect the trace - make sure the keyword arguments were forwarded correctly.
    trace = StructArray(trace)
    @test trace.incrementer == range(increment; length = iters, step = increment)

    # Also, check that the `prehook` and `posthook` counts of our process are correct.
    @test process.prehook_count == iters
    @test process.posthook_count == iters

    # Check inference works properly.
    @inferred inference_check()

    # Try some other variants of `snoop`
    #
    # Also make sure that placing in a return value is forwareded properly to the top level.
    trace, ret = snoop(measurements, getpid(); increment = increment) do snooper
        for _ in SystemSnoop.Timeout(Dates.Second(1))
            measure!(snooper)
            sleep(0.1)
        end
        return "test me"
    end

    @test isa(trace, StructArrays.StructArray)
    @test ret == "test me"

    # Lave a little wiggle room.
    @test length(trace) > 9
    @test length(trace) < 11

    # `Cmd` version
    trace = snoop(measurements, `sleep 1`; increment = increment) do snooper
        for _ in SystemSnoop.Timeout(Dates.Second(1))
            measure!(snooper)
            sleep(0.1)
        end
    end
    @test length(trace) > 9
    @test length(trace) < 11

    # Automatic Global Process Dispatch
    trace = snoop(measurements; increment = increment) do snooper
        for _ in SystemSnoop.Timeout(Dates.Second(1))
            measure!(snooper)
            sleep(0.1)
        end
    end
    @test length(trace) > 9
    @test length(trace) < 11
end

