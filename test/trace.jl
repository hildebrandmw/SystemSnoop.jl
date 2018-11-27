
@testset "Testing Sample" begin
    # Strategy: construct a test collection and then run tests on that.
    # Note that the actual field in the "vmas" category of "Sample" doesn't matter for
    # trace extraction - it's just a bookkeeping strategy.
    isactive    = MemSnoop.isactive

    VMAs = [
        [VMA(1, 10)],
        [VMA(1, 11), VMA(20, 30)],
        [VMA(0, 8)],
    ]

    A = SortedRangeVector([UInt(1):UInt(3), UInt(5):UInt(8)])
    B = SortedRangeVector([UInt(2):UInt(2)])
    C = SortedRangeVector([UInt(4):UInt(6)])

    trace = Sample.(VMAs, [A,B,C])

    # Start testing!
    @test isactive(trace[1], UInt(0))  == false
    @test isactive(trace[1], UInt(1))  == true
    @test isactive(trace[1], UInt(4))  == false
    @test isactive(trace[1], UInt(5))  == true
    @test isactive(trace[1], UInt(8))  == true
    @test isactive(trace[1], UInt(9))  == false

    @test MemSnoop.wss(trace[1]) == 7
    @test MemSnoop.wss(trace[2]) == 1
    @test MemSnoop.wss(trace[3]) == 3

    @test MemSnoop.pages(trace[1]) == Set([1, 2, 3, 5, 6, 7, 8])
    @test MemSnoop.pages(trace[2]) == Set([2])
    @test MemSnoop.pages(trace[3]) == Set([4, 5, 6])

    @test vmas(trace) == [VMA(0, 11), VMA(20, 30)]

    @test pages(trace) == [1, 2, 3, 4, 5, 6, 7, 8]

    #####
    ##### Test Union
    #####

    # Trace 1 and 2
    expected_12 = Sample(
        [VMA(1, 11), VMA(20, 30)],
        SortedRangeVector([UInt(1):UInt(3), UInt(5):UInt(8)]),
    )
    @test union(trace[1], trace[2]) == expected_12
    @test union(trace[2], trace[1]) == expected_12

    # Traces 2 and 3
    expected_23 = Sample(
        [VMA(0, 11), VMA(20, 30)],
        SortedRangeVector([UInt(2):UInt(2), UInt(4):UInt(6)])
    )
    @test union(trace[2], trace[3]) == expected_23
    @test union(trace[3], trace[2]) == expected_23

    # Traces 1 and 3
    expected_13 = Sample(
        [VMA(0, 10)],
        SortedRangeVector([UInt(1):UInt(8)])
    )
    @test union(trace[1], trace[3]) == expected_13
    @test union(trace[3], trace[1]) == expected_13

    # Traces 1, 2, and 3
    expected = Sample(
        [VMA(0, 11), VMA(20, 30)],
        SortedRangeVector([UInt(1):UInt(8)])
    )
    @test union(trace[1], trace[2], trace[3]) == expected
    @test union(trace[1], trace[3], trace[2]) == expected
    @test union(trace[2], trace[1], trace[3]) == expected
    @test union(trace[2], trace[3], trace[1]) == expected
    @test union(trace[3], trace[1], trace[2]) == expected
    @test union(trace[3], trace[2], trace[1]) == expected


    #####
    ##### Bitmap
    #####

    sub = MemSnoop.bitmap(trace, VMA(0, 1))
    expected =
        [ false false false;  # 0
          true  false false ] # 1

    @test sub == expected


    sub = MemSnoop.bitmap(trace, VMA(1, 4))
    expected = [ true  false false; # 1
                 true  true  false; # 2
                 true  false false; # 3
                 false false true]  # 4
    @test sub == expected


    # Make sure the size we get is what we expect for a large extraction
    sub = MemSnoop.bitmap(trace, VMA(0, 10))
    @test size(sub) == (11, length(trace))


    # Get a VMA that is entirely out of range.
    sub = MemSnoop.bitmap(trace, VMA(20, 30))
    @test all(isequal(false), sub)
end
