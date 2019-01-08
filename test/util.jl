@testset "Testing Utilities" begin
    buffer = SystemSnoop.VMA[] 
    SystemSnoop.getvmas!(buffer, getpid())
    @test length(buffer) > 0
    @time SystemSnoop.getvmas!(buffer, getpid())
end
