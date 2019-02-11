@testset "Testing VMAs" begin
    import SystemSnoop.IdlePages

    a = IdlePages.VMA(0, 10, "hello")
    @test IdlePages.startaddress(a) == 0
    @test IdlePages.stopaddress(a) == 4096 * 10
    @test length(a) == 11

    # Test non-overlapping regions
    b = IdlePages.VMA(0, 10, "hello")
    c = IdlePages.VMA(11, 20, "")
    @test b < c
    @test !(c < b)
    @test !IdlePages.overlapping(b, c)
    @test !IdlePages.overlapping(c, b)
    @test !IdlePages.issubset(b, c)
    @test !IdlePages.issubset(c, b)

    # Test overlapping regions
    e = IdlePages.VMA(0, 10, "hello")
    f = IdlePages.VMA(9, 20, "")
    @test !(e < f)
    @test !(f < e)
    @test IdlePages.overlapping(e, f)
    @test IdlePages.overlapping(f, e)
    @test !IdlePages.issubset(e, f)
    @test !IdlePages.issubset(f, e)
    @test union(e, f) == IdlePages.VMA(0, 20, "hello")
    @test union(f, e) == IdlePages.VMA(0, 20, "")

    # Test subset regions
    g = IdlePages.VMA(0, 10, "hello") 
    h = IdlePages.VMA(4, 5, "")
    @test !(g < h)
    @test !(h < g)
    @test IdlePages.overlapping(g, h)
    @test IdlePages.overlapping(h, g)
    @test IdlePages.issubset(h, g)
    @test !IdlePages.issubset(g, h)
    @test union(g, h) == IdlePages.VMA(0, 10, "hello")
    @test union(h, g) == IdlePages.VMA(0, 10, "")

    # Test Compaction
    i = IdlePages.VMA(0, 10, "") 
    j = IdlePages.VMA(4, 5, "")
    k = IdlePages.VMA(9, 11, "")
    l = IdlePages.VMA(11, 20, "")
    m = IdlePages.VMA(21, 30, "")

    # After compaction, we expect i, j, k, and l to all overlap and thus be reduced to
    # a single region.
    #
    # Try this for all permutations
    vmas = [i, j, k, l, m]  

    for ordering in permutations(vmas)
        reduced = IdlePages.compact(ordering)

        @test reduced == [IdlePages.VMA(0, 20, ""), IdlePages.VMA(21, 30, "")]
        @test reduced != ordering
    end
end
