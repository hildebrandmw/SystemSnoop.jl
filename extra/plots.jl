# Run the sample workloads and save the traces to the working directory for later plotting.
tests = ("single", "double")

# Dependencies
using MemSnoop, Plots
pyplot()

include("build.jl")
builddir = build(tests)

# Function to generate the plots.
function plot(trace::Vector{MemSnoop.Sample})
    data = [MemSnoop.gettrace(trace, v) for v in MemSnoop.vmas(trace)]
    alldata = vcat(data...)
    return heatmap(alldata)
end

# Run and snoop the tests
for test in tests
    @info "Running workload: $test"
    fullpath = joinpath(builddir, test)
    pid, process, pipe = MemSnoop.launch(fullpath)
    trace = MemSnoop.trace(pid; sampletime = 1)

    # Save the trace.
    name, _ =  splitext(test)
    MemSnoop.save("$test.jls", trace)
    plt = plot(trace)

    savefig("$test.png")
    MemSnoop.save("$name.trace", trace) 
end
