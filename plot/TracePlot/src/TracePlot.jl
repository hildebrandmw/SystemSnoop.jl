module TracePlot

# stdlib
using Serialization

# packages
using MemSnoop
using Makie

export plot, load

load(path) = open(f -> deserialize(f), path)

# The recipe! - This will get called for plot(!)(trace::Trace)
function plot(trace::MemSnoop.Trace)
    # Get all of the virtual pages seen in the trace.
    all_addresses = MemSnoop.addresses(trace)

    bitmap = [MemSnoop.isactive(sample, address) for address in all_addresses, sample in trace]

    return heatmap(bitmap)
end

end
