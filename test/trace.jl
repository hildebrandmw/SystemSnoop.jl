@testset "Testing RangeVector" begin
    R = MemSnoop.RangeVector(UnitRange{Int}[])

    push!(R, 1)
    @test R.ranges == [1:1]
    @test length(R) == 1
    push!(R, 2)
    @test R.ranges == [1:2]
    @test length(R) == 2
    push!(R, 10)
    @test R.ranges == [1:2, 10:10]
    @test length(R) == 3
    push!(R, 12)
    @test R.ranges == [1:2, 10:10, 12:12]
    @test length(R) == 4

    # Try iteration and collection
    @test eltype(R) == Int64 
    X = collect(R)
    @test X == [1, 2, 10, 12]

    # Test some searching
    @test MemSnoop.insorted(R, 1) == true
    @test MemSnoop.insorted(R, 2) == true
    @test MemSnoop.insorted(R, 3) == false
    @test MemSnoop.insorted(R, 0) == false
    @test MemSnoop.insorted(R, 10) == true
    @test MemSnoop.insorted(R, 11) == false
    @test MemSnoop.insorted(R, 13) == false

    @test MemSnoop.lastelement(R) == 12
end
