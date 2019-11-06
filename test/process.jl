@testset "Process" begin
    G = SystemSnoop.GlobalProcess()   
    @test isrunning(G)
    @test SystemSnoop.prehook(G) == nothing
    @test SystemSnoop.posthook(G) == nothing

    process = run(`sleep 5`; wait = false)
    pid = getpid(process)
    sp = SystemSnoop.SnoopedProcess{SystemSnoop.Pausable}(pid)
    @test isrunning(sp)

    # Command to get the status of a process.
    getstatus(pid) = chomp(read(`ps -q $pid -o state --no-headers`, String))

    @test getstatus(pid) == "S"

    SystemSnoop.prehook(sp)
    status = read(`ps -q $pid -o state --no-headers`)
    @test getstatus(pid) == "T"

    SystemSnoop.posthook(sp)
    @test getstatus(pid) == "S"
    kill(process)
end
