@testset "Testing VMAs" begin

    a = VMA(UInt(0), UInt(10), "hello")
    @test MemSnoop.startaddress(a) == 0
    @test MemSnoop.stopaddress(a) == 4096 * 10
    @test length(a) == 11

    # Test non-overlapping regions
    b = VMA(0, 10, "hello")
    c = VMA(11, 20, "")
    @test b < c
    @test !(c < b)
    @test !MemSnoop.overlapping(b, c)
    @test !MemSnoop.overlapping(c, b)
    @test !MemSnoop.issubset(b, c)
    @test !MemSnoop.issubset(c, b)

    # Test overlapping regions
    e = VMA(0, 10, "hello")
    f = VMA(9, 20, "")
    @test !(e < f)
    @test !(f < e)
    @test MemSnoop.overlapping(e, f)
    @test MemSnoop.overlapping(f, e)
    @test !MemSnoop.issubset(e, f)
    @test !MemSnoop.issubset(f, e)
    @test union(e, f) == MemSnoop.VMA(0, 20, "hello")
    @test union(f, e) == MemSnoop.VMA(0, 20, "")

    # Test subset regions
    g = VMA(0, 10, "hello") 
    h = VMA(4, 5, "")
    @test !(g < h)
    @test !(h < g)
    @test MemSnoop.overlapping(g, h)
    @test MemSnoop.overlapping(h, g)
    @test MemSnoop.issubset(h, g)
    @test !MemSnoop.issubset(g, h)
    @test union(g, h) == MemSnoop.VMA(0, 10, "hello")
    @test union(h, g) == MemSnoop.VMA(0, 10, "")

    # Test Compaction
    i = VMA(0, 10, "") 
    j = VMA(4, 5, "")
    k = VMA(9, 11, "")
    l = VMA(11, 20, "")
    m = VMA(21, 30, "")

    # After compaction, we expect i, j, k, and l to all overlap and thus be reduced to
    # a single region.
    #
    # Try this for all permutations
    vmas = [i, j, k, l, m]  

    for ordering in permutations(vmas)
        reduced = MemSnoop.compact(ordering)

        @test reduced == [VMA(0, 20, ""), VMA(21, 30, "")]
        @test reduced != ordering
    end
end
