@testset "Testing VMAs" begin
    a = SystemSnoop.VMA(0, 10, "hello")
    @test SystemSnoop.startaddress(a) == 0
    @test SystemSnoop.stopaddress(a) == 4096 * 10
    @test length(a) == 11

    # Test non-overlapping regions
    b = SystemSnoop.VMA(0, 10, "hello")
    c = SystemSnoop.VMA(11, 20, "")
    @test b < c
    @test !(c < b)
    @test !SystemSnoop.overlapping(b, c)
    @test !SystemSnoop.overlapping(c, b)
    @test !SystemSnoop.issubset(b, c)
    @test !SystemSnoop.issubset(c, b)

    # Test overlapping regions
    e = SystemSnoop.VMA(0, 10, "hello")
    f = SystemSnoop.VMA(9, 20, "")
    @test !(e < f)
    @test !(f < e)
    @test SystemSnoop.overlapping(e, f)
    @test SystemSnoop.overlapping(f, e)
    @test !SystemSnoop.issubset(e, f)
    @test !SystemSnoop.issubset(f, e)
    @test union(e, f) == SystemSnoop.VMA(0, 20, "hello")
    @test union(f, e) == SystemSnoop.VMA(0, 20, "")

    # Test subset regions
    g = SystemSnoop.VMA(0, 10, "hello") 
    h = SystemSnoop.VMA(4, 5, "")
    @test !(g < h)
    @test !(h < g)
    @test SystemSnoop.overlapping(g, h)
    @test SystemSnoop.overlapping(h, g)
    @test SystemSnoop.issubset(h, g)
    @test !SystemSnoop.issubset(g, h)
    @test union(g, h) == SystemSnoop.VMA(0, 10, "hello")
    @test union(h, g) == SystemSnoop.VMA(0, 10, "")

    # Test Compaction
    i = SystemSnoop.VMA(0, 10, "") 
    j = SystemSnoop.VMA(4, 5, "")
    k = SystemSnoop.VMA(9, 11, "")
    l = SystemSnoop.VMA(11, 20, "")
    m = SystemSnoop.VMA(21, 30, "")

    # After compaction, we expect i, j, k, and l to all overlap and thus be reduced to
    # a single region.
    #
    # Try this for all permutations
    vmas = [i, j, k, l, m]  

    for ordering in permutations(vmas)
        reduced = SystemSnoop.compact(ordering)

        @test reduced == [SystemSnoop.VMA(0, 20, ""), SystemSnoop.VMA(21, 30, "")]
        @test reduced != ordering
    end
end
