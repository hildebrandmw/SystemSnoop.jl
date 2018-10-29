# The program "single.cpp" iterates over a single large array. I expect the following 
# items to be output by "single.cpp" to STDOUT in new lines in this order
# 
# 1. The base address of the array
# 2. The end address of the array
# 3. Print a message when it begins accessing the array
# 4. Print a message when it finished accessing the array
#
# The general strategy here is to use the first two print outs to determine which addresses
# we expect to see in the trace.
#
# The third print out lets us know when to begin sampling. IE, when we expect these pages
# to be active
#
# When we get the third print, take a trace again and make sure that the large array
# is correctly marked as idle
@testset "Testing program `single`" begin
    pagesize = 4096
    # Setup the path to the single test
    path = joinpath(BUILDDIR, "single")

    # Launch the test program
    pid, process, pipe = MemSnoop.launch(path)

    # Pass a single length range as the iterator so we only take one sample.
    trace = MemSnoop.trace(pid; sampletime = 2)

    # Read the start and end addresses from the pipe
    # Convert these addresses into pages.
    start_address = parse(UInt64, readline(pipe))  
    end_address = parse(UInt64, readline(pipe))

    start_page = div(start_address, pagesize) * pagesize
    end_page = div(end_address, pagesize) * pagesize

    # First sample should have all the hits
    sample = first(trace)
    for frame in start_page:pagesize:end_page
        @test MemSnoop.isactive(sample, frame)
        if !MemSnoop.isactive(sample, frame)
            @show start_page
            @show end_page
            @show frame
            break
        end
    end

    # Last sample should have no hits
    # I think there's some cleanup code or something that runs near the end, so take the
    # second to last record.
    sample = trace[end-1]
    for frame in start_page:pagesize:end_page
        @test !MemSnoop.isactive(sample, frame)
        if MemSnoop.isactive(sample, frame)
            @show start_page
            @show end_page
            @show frame
            break
        end
    end
end
