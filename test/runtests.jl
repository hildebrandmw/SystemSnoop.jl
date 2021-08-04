using SystemSnoop
using Test
using Dates: Dates
using StructArrays

@testset "Testing SmartSample" begin
    times = Dates.DateTime[]
    timestep = Dates.Millisecond(100)
    sampler = SystemSnoop.SmartSample(timestep)
    for i in 1:10
        sleep(sampler)
        push!(times, Dates.now())
    end

    # The first sample is unreliable for some reason - just trash it.
    gaps = Dates.value.(Dates.Millisecond.(diff(times)))
    popfirst!(gaps)

    for g in gaps
        @test Dates.value(timestep) - 2 <= g
        @test g <= Dates.value(timestep) + 2
    end

    # Now, make sure the logic for skipping time steps works. The following should work
    start_iter = sampler.iteration
    sleep(0.1)
    sleep(sampler)
    stop_iter = sampler.iteration

    # The log here is that the smart sampler should skip iterations.
    @test stop_iter > start_iter + 1
end

#####
##### Measurement Routine
#####

# Require that `kw` are forwarded
mutable struct Incrementer
    prepare_count::Int
    measurement_count::Int
    clean_count::Int
end

function SystemSnoop.prepare(x::Incrementer)
    x.prepare_count += 1
    return nothing
end

function SystemSnoop.measure(x::Incrementer)
    x.measurement_count += 1
    return x.measurement_count
end

function SystemSnoop.clean(x::Incrementer)
    x.clean_count += 1
    return nothing
end

@testset "snooped" begin
    # Use the `TestA` code from base.jl
    incrementer = Incrementer(0, 0, 0)
    measurements = (
        timestamp = SystemSnoop.Timestamp(),
        incrementer = incrementer,
    )

    # Call the outer `snoop` function with our dummy process. Make sure everything runs
    # smoothly.
    iters = 3
    increment = 20
    trace = @snooped measurements 1000 sleep(2)

    # Test that inference works correctly
    expected = Base.promote_op(
        SystemSnoop.snooploop,
        typeof(measurements),
        typeof(1000),
        NamedTuple{},
        Threads.Atomic{Int},
        Threads.Atomic{Int},
    )
    @test typeof(trace) == expected

    # Were the correct methods called?
    @test incrementer.prepare_count == 1
    @test incrementer.clean_count == 1

    num_measurements = incrementer.measurement_count
    @test num_measurements > 0
    @test trace.incrementer == 1:num_measurements
end

