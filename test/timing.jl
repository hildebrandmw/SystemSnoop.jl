@testset "Timing Operations" begin
    # Create a process based on the Julia instance we are using.
    process = MemSnoop.Process(getpid())

    println()
    println("Testing Reads from the Idle Buffer")
    @btime read!($(MemSnoop.IDLE_BITMAP), $(process.buffer))

    println()
    println("Testing Time it takes to Seek Write Idle Pages") 
    MemSnoop.getvmas!(process)
    @btime MemSnoop.markidle($(process))

    println()
    println("Testing Time it takes to read idle pages")
    MemSnoop.getvmas!(process)
    @btime MemSnoop.readidle($(process))
end
