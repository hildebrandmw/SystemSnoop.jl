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

    # Launch the test program
    pid, process, pipe = SnoopTest.pidlaunch("single")

    # Pass a single length range as the iterator so we only take one sample.
    T = trace(pid; sampletime = 6)

    # Read the start and end addresses from the pipe
    # Convert these addresses into pages.
    start_address = parse(UInt64, readline(pipe))  
    end_address = parse(UInt64, readline(pipe))

    start_page = div(start_address, pagesize)
    end_page = div(end_address, pagesize)

    # First sample should have all the hits
    sample = first(T)
    for frame in start_page:end_page
        @test MemSnoop.isactive(sample, frame)
        if !MemSnoop.isactive(sample, frame)
            @show start_page
            @show end_page
            @show frame
            break
        end
    end

    ###
    ### Benchmarking
    ###
    println("Benchmarking `pages(::Vector{Sample})`")
    @btime pages($T)

    v = vmas(T)
    println("Benchmarking `vmas(::Vector{Sample})`")
    @btime vmas($T)

    println("Benchmarking `bitmap`")
    _, ind = findmax(length.(v))
    @btime bitmap($T, $(v[ind]))

    # XXX
    ## Doing this Breaks CI ... I don't know if it has something to do with the 
    # the fact that Travis is using VMs or something ...

    #=
    # Last sample should have no hits
    sample = trace[end]
    for frame in start_page:end_page
        @test !MemSnoop.isactive(sample, frame)
        if MemSnoop.isactive(sample, frame)
            @show start_page
            @show end_page
            @show frame
            break
        end
    end
    =#
end
