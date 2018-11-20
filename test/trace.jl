@testset "Testing RangeVector" begin
    R = MemSnoop.RangeVector(UnitRange{Int}[])

    push!(R, 1)
    @test R.ranges == [1:1]
    @test length(R) == 1
    @test MemSnoop.lastelement(R) == 1

    push!(R, 2)
    @test R.ranges == [1:2]
    @test length(R) == 1
    @test MemSnoop.lastelement(R) == 2

    push!(R, 10)
    @test R.ranges == [1:2, 10:10]
    @test length(R) == 2
    @test MemSnoop.lastelement(R) == 10

    push!(R, 12)
    @test R.ranges == [1:2, 10:10, 12:12]
    @test length(R) == 3
    @test MemSnoop.lastelement(R) == 12

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
    @test MemSnoop.insorted(R, 1) == true
    @test MemSnoop.insorted(R, 2) == true
    @test MemSnoop.insorted(R, 3) == false
    @test MemSnoop.insorted(R, 0) == false
    @test MemSnoop.insorted(R, 10) == true
    @test MemSnoop.insorted(R, 11) == false
    @test MemSnoop.insorted(R, 12) == true
    @test MemSnoop.insorted(R, 13) == false

    @test MemSnoop.lastelement(R) == 12
end

@testset "Testing Sample" begin
    # Strategy: construct a test collection and then run tests on that.
    # Note that the actual field in the "vmas" category of "Sample" doesn't matter for
    # trace extraction - it's just a bookkeeping strategy.
    RangeVector = MemSnoop.RangeVector
    Sample      = MemSnoop.Sample
    isactive    = MemSnoop.isactive
    VMA         = MemSnoop.VMA


    null = VMA[]
    
    A = RangeVector([UInt(1):UInt(3), UInt(5):UInt(8)])
    B = RangeVector([UInt(2):UInt(2)])
    C = RangeVector([UInt(4):UInt(6)])

    trace = Sample.(Ref(null), [A,B,C])

    # Start testing!
    @test isactive(trace[1], UInt(0))  == false
    @test isactive(trace[1], UInt(1))  == true
    @test isactive(trace[1], UInt(4))  == false
    @test isactive(trace[1], UInt(5))  == true
    @test isactive(trace[1], UInt(8))  == true
    @test isactive(trace[1], UInt(9))  == false

    # Start extracting VMAs
    sub = MemSnoop.bitmap(trace, VMA(UInt(0), UInt(1), ""))
    expected = 
        [ false false false;  # 0
          true  false false ] # 1     

    @test sub == expected


    sub = MemSnoop.bitmap(trace, VMA(UInt(1), UInt(4), ""))
    expected = [ true  false false; # 1
                 true  true  false; # 2
                 true  false false; # 3
                 false false true]  # 4
    @test sub == expected


    # Make sure the size we get is what we expect for a large extraction
    sub = MemSnoop.bitmap(trace, VMA(UInt(0), UInt(10), ""))
    @test size(sub) == (11, length(trace))


    # Get a VMA that is entirely out of range.
    sub = MemSnoop.bitmap(trace, VMA(UInt(20), UInt(30), "")) 
    @test all(isequal(false), sub)
end
