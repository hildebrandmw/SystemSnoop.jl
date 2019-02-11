@testset "Testing Utilities" begin
    buffer = SystemSnoop.IdlePages.VMA[] 
    SystemSnoop.IdlePages.getvmas!(buffer, getpid())
    @test length(buffer) > 0
    @time SystemSnoop.IdlePages.getvmas!(buffer, getpid())
end
