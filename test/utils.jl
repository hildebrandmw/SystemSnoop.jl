@testset "Testing Special Iterators" begin
    # Run for 3 seconds
    runtime = Dates.Second(1)

    timeout = SystemSnoop.Timeout(runtime)
    starttime = Dates.now()
    for _ in timeout
    end
    stoptime = Dates.now()

    # If this ran for 3 seconds, then the time difference between start and finish should
    # be greater than 3000 Milliseconds
    actual_runtime = Dates.Millisecond(stoptime - starttime)
    @test 1000 <= Dates.value(actual_runtime)

    # Also check that it responds quickly by setting an upper bound on the runtime.
    @test Dates.value(actual_runtime) <= 1005
end

@testset "Testing PID Utils" begin
    @test isrunning(getpid()) == true
    @test isrunning(0) == false

    process = run(`sleep 5`; wait = false)
    pid = getpid(process)

    # Command to get the status of a process.
    # From the `ps` manual:
    #
    # PROCESS STATE CODES
    # Here are the different values that the s, stat and state output
    # specifiers (header "STAT" or "S") will display to describe the
    # state of a process:

    #    D    uninterruptible sleep (usually IO)
    #    R    running or runnable (on run queue)
    #    S    interruptible sleep (waiting for an event to complete)
    #    T    stopped by job control signal
    #    t    stopped by debugger during the tracing
    #    W    paging (not valid since the 2.6.xx kernel)
    #    X    dead (should never be seen)
    #    Z    defunct ("zombie") process, terminated but not reaped by its parent
    getstatus(pid) = chomp(read(`ps -q $pid -o state --no-headers`, String))

    @test getstatus(pid) == "S"

    pause(pid)
    status = read(`ps -q $pid -o state --no-headers`)
    @test getstatus(pid) == "T"

    resume(pid)
    @test getstatus(pid) == "S"
    kill(process)
end

@testset "Testing SmartSample" begin
    times = Dates.DateTime[]
    timestep = Dates.Millisecond(100)
    sampler = SystemSnoop.SmartSample(timestep)
    for i in 1:10
        sleep(sampler)
        push!(times, Dates.now())
    end
    gaps = Dates.value.(Dates.Millisecond.(diff(times)))

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

