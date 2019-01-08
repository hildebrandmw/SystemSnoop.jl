@testset "Testing SortedRangeVector" begin
    R = SystemSnoop.SortedRangeVector(UnitRange{Int}[])

    push!(R, 1)
    @test R.ranges == [1:1]
    @test length(R) == 1
    @test SystemSnoop.lastelement(R) == 1

    push!(R, 2)
    @test R.ranges == [1:2]
    @test length(R) == 1
    @test SystemSnoop.lastelement(R) == 2

    push!(R, 10)
    @test R.ranges == [1:2, 10:10]
    @test length(R) == 2
    @test SystemSnoop.lastelement(R) == 10

    push!(R, 12)
    @test R.ranges == [1:2, 10:10, 12:12]
    @test length(R) == 3
    @test SystemSnoop.lastelement(R) == 12

    # Test "getindex"
    @test R[1] == 1:2
    @test R[2] == 10:10
    @test R[3] == 12:12

    # Test "size"
    @test size(R) == (3,)

    # ------------------------
    # Test "searchsortedfirst"

    # Before the first element
    @test searchsortedfirst(R, 0) == 1

    # Inside the range vector
    @test searchsortedfirst(R, 1) == 1
    @test searchsortedfirst(R, 2) == 1
    @test searchsortedfirst(R, 3) == 2
    @test searchsortedfirst(R, 10) == 2
    @test searchsortedfirst(R, 11) == 3

    # After the last element
    @test searchsortedfirst(R, 100) == 4


    #-------------------------
    # Iteration and collection
    @test eltype(R) == UnitRange{Int64}
    X = collect(Base.Iterators.flatten(R))
    @test X == [1, 2, 10, 12]

    # Test some searching
    @test in(1, R) == true
    @test in(2, R) == true
    @test in(3, R) == false
    @test in(0, R) == false
    @test in(10, R) == true
    @test in(11, R) == false
    @test in(12, R) == true
    @test in(13, R) == false

    @test SystemSnoop.lastelement(R) == 12

    #####
    ##### Test unions
    #####

    # Dict for holding the results of benchmarks
    benchmark_dict = Dict{Symbol,Any}()

    # Union of two null elements
    a = SystemSnoop.SortedRangeVector{Int}()
    b = SystemSnoop.SortedRangeVector{Int}()

    @test union(a, b) == SystemSnoop.SortedRangeVector{Int}()
    benchmark_dict[:empty] = @benchmark union($a, $b)

    # One populated range vector and one empty range vector.
    a = SystemSnoop.SortedRangeVector([1:2, 4:10, 15:15])
    b = SystemSnoop.SortedRangeVector{Int}()

    @test union(a, b) == a
    @test union(b, a) == a
    benchmark_dict[:second_empty] = @benchmark union($a, $b)
    benchmark_dict[:first_empty] = @benchmark union($b, $a)

    # Now try taking unions for real
    a = SystemSnoop.SortedRangeVector([1:2, 10:20])
    b = SystemSnoop.SortedRangeVector([22:30])
    expected = SystemSnoop.SortedRangeVector([1:2, 10:20, 22:30])
    @test union(a, b) == expected
    @test union(b, a) == expected

    a = SystemSnoop.SortedRangeVector([1:2, 3:4])
    b = SystemSnoop.SortedRangeVector([2:3])
    expected = SystemSnoop.SortedRangeVector([1:4])
    @test union(a, b) == expected
    @test union(b, a) == expected

    a = SystemSnoop.SortedRangeVector([1:2, 5:6, 10:11])
    b = SystemSnoop.SortedRangeVector([3:4, 12:12, 19:20])
    expected = SystemSnoop.SortedRangeVector([1:6, 10:12, 19:20])
    @test union(a, b) == expected
    @test union(b, a) == expected

    a = SystemSnoop.SortedRangeVector([1:2, 3:4, 10:12])
    b = SystemSnoop.SortedRangeVector([3:5, 10:11])
    expected = SystemSnoop.SortedRangeVector([1:5, 10:12])
    @test union(a, b) == expected
    @test union(b, a) == expected

    a = SystemSnoop.SortedRangeVector([1:2, 10:12])
    b = SystemSnoop.SortedRangeVector([1:3, 9:13])
    expected = SystemSnoop.SortedRangeVector([1:3, 9:13])
    @test union(a, b) == expected
    @test union(b, a) == expected
    benchmark_dict[:trial_1] = @benchmark union($a, $b)


    # Display benchmark results
    for (k,v) in benchmark_dict
        println("Benchmark: $k")
        display(v)
        println()
        println()
    end
end
