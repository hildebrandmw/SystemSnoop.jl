@testset "Timing Operations" begin
    # Create a process based on the Julia instance we are using.
    process = MemSnoop.Process(getpid())

    println()
    println("Testing Reads from the Idle Buffer")
    @btime read!($(MemSnoop.IDLE_BITMAP), $(process.bitmap))

    println()
    println("Testing Time it takes to Seek Write Idle Pages") 
    MemSnoop.getvmas!(process)
    @btime MemSnoop.markidle($(process))

    println()
    println("Testing Time it takes to read idle pages")
    MemSnoop.getvmas!(process)
    @btime MemSnoop.readidle($(process))

    # Use the "allwrite" process
    process = MemSnoop.Process{MemSnoop.AllWrite}(getpid())
    println()
    println("Testing Time it takes to AllWrite Idle Pages")
    MemSnoop.getvmas!(process)
    @btime MemSnoop.markidle($(process))
end
