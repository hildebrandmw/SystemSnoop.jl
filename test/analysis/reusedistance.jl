@testset "Testing BucketStack" begin
    B = SystemSnoop.BucketStack{Int}()
    @test length(B) == 0

    push!(B, Set([1,2,3]))
    @test length(B) == 1
    # Do some internal poking
    @test B.buckets == [Set([1,2,3])]

    # Make sure the index record is working correctly
    index_record = B.index_record
    @test index_record[1] == 1
    @test index_record[2] == 1
    @test index_record[3] == 1

    # Now, if we add a new set to the collection, we have to make sure everything
    # updates correctly.
    push!(B, Set([1, 4, 5]))
    @test B.buckets == [
        Set([2,3]),
        Set([1,4,5]),
    ]

    @test index_record[1] == 2
    @test index_record[2] == 1
    @test index_record[3] == 1
    @test index_record[4] == 2
    @test index_record[5] == 2

    # One more push
    push!(B, Set([1, 3, 5, 6]))
    @test B.buckets == [
        Set([2]),
        Set([4]),
        Set([1, 3, 5, 6]),
    ]

    @test index_record[1] == 3
    @test index_record[2] == 1
    @test index_record[3] == 3
    @test index_record[4] == 2
    @test index_record[5] == 3
    @test index_record[6] == 3
end

#####
##### Test inter_reuse
#####

@testset "Testing `inter_reuse`" begin
    # Strategy: Construct a synthetic example where we know what the expected reuse
    # distances are supposed to be.

    buckets = Set.([
        [1, 2, 3, 4],
        [1, 5],
        [1, 2],
        [2, 4, 5, 6],
    ])

    # Stack State
    #
    # Iteration 1
    #
    # [1,2,3,4]
    #
    # Upper Distances:
    #   1,2,3,4 => -1
    # Lower Distances:
    #   1,2,3,4 => -1
    #
    #
    # Iteration 2
    #
    # [1,5]        [1,5]
    # [1,2,3,4] => [2,3,4]
    #
    # Upper Distances:
    #   1 => 5,
    #   5 => -1
    # Lower Distances:
    #   1 => 0,
    #   5 => -1
    #
    # Iteration 3
    #
    # [1,2]   => [1,2]
    # [1,5]   => [5]
    # [2,3,4] => [3,4]
    #
    # Upper Distances:
    #   1 => 3,
    #   2 => 5
    # Lower Distances:
    #   1 => 0,
    #   2 => 3,
    #
    # Iteration 4
    #
    # [2,4,5,6] => [2,4,5,6]
    # [1,2]     => [1]
    # [5]       => [5]
    # [3,4]     => [3]
    #
    # Upper Distances:
    #   2,5 => 5,
    #   4 => 6,
    #   6 => -1
    # Lower Distances:
    #   2 => 0,
    #   4 => 4,
    #   5 => 3,
    #   6 => -1

    # Generate the expected upper and lower bound histograms
    expected_upperbound = Dict(
        -1 => 6,
        3 => 1,
        5 => 4,
        6 => 1
    )

    # expected_lowerbound = Dict(
    #     -1 => 6,
    #     0 => 3,
    #     3 => 3
    # )

    bounds = SystemSnoop.inter_reuse(buckets)
    @test bounds.upper == expected_upperbound
end
