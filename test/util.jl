@testset "Testing Utilities" begin
    buffer = MemSnoop.VMA[] 
    MemSnoop.getvmas!(buffer, getpid())
    @test length(buffer) > 0
    @time MemSnoop.getvmas!(buffer, getpid())
end
