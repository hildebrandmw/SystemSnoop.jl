struct Swap <: AbstractMeasurement end

prepare(S::Swap, args...) = Vector{Int64}()

# Example output:
#
# Filename              Type        Size        Used    Priority
# /dev/sda2             partition   1048572     0       -2
# /mnt/256g.swap        file        268435452   201472  0
#
# Just sum the "used" fields of each line.
function measure(::Swap, args...)::Int64
    tally = 0
    buffer = IOBuffer(read(`swapon -s`))

    for ln in drop(eachline(buffer), 1)
        used = safeparse(Int64, split(ln)[4])
        tally += used
    end
    return tally
end
