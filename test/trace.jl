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
    end
end

@testset "Trace" begin
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
    trace = snoop(process, measurements; increment = increment) do snooper
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
end

