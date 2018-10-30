@testset "Testing Utilities" begin
    buffer = MemSnoop.VMA[] 
    MemSnoop.getvmas!(buffer, getpid())
    @test length(buffer) > 0
    for vma in buffer
        println(vma)
    end
    @time MemSnoop.getvmas!(buffer, getpid())
end
