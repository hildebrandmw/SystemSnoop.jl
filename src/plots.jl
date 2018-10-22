# Makie recipe for generating a heatmap of active addresses.
#
# Refer to: 
#
# http://makie.juliaplots.org/stable/examples-meshscatter.html#Type-recipe-for-molecule-simulation-1
#
# for how I'm constructing this recipe.
#
# The basic idea behind a recipe is that you can export various function to generate
# the correct plot without relying on the whole plotting library as a dependency.
import AbstractPlotting
import AbstractPlotting: Plot, plot!, to_value


# The recipe! - This will get called for plot(!)(trace::Trace)
function AbstractPlotting.plot!(p::Plot(Trace))
    # Get the trace out of the plot object.
    trace = to_value(p[1]) 

    # Get all of the virtual pages seen in the trace.
    addresses = addresses(trace)

    bitmap = [washit(sample, address) for sample in trace, address in addresses]

    heatmap!(p, bitmap)
end
