"""
Return the amount of swap used by a process.

This is performed by reading from `/proc/[pid]/smaps` and accumulating all of the swap
values.

TODO
----
The implementation of this is not terribly well optimized.
"""
struct Smaps <: AbstractMeasurement end

prepare(S::Smaps, args...) = Vector{Int64}()

# TODO: This can probably be sped up by quite a bit.
function measure(S::Smaps, process)::Int64
    tally = 0
    pid = getpid(process)
    tally = pidsafeopen("/proc/$pid/smaps", pid) do f

        tally = 0
        for ln in eachline(f)
            if startswith(ln, "Swap")
                val = safeparse(Int64, split(ln)[2])
                tally += val
            end
        end
        return tally
    end
    return tally
end
