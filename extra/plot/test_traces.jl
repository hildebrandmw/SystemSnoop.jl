# Run the sample workloads and save the traces to the working directory for later plotting.
tests = ("single", "double")

# Dependencies
using Serialization, MemSnoop, Plots
pyplot()

# Build the tests
builddir = joinpath(@__DIR__, "build")
ispath(builddir) || mkdir(builddir)

# Compile the tests
for test in tests
    run(`c++ -std=c++1y -O2 src/$test.cpp -o build/$test`)
end

# Function to generate the plots.
function plot(trace::Vector{MemSnoop.Sample})
    return heatmap(MemSnoop.ArrayView(trace))
end

# Run and snoop the tests
for test in tests
    @info "Running workload: $test"
    fullpath = joinpath(builddir, test)
    pid, process, pipe = MemSnoop.launch(fullpath)
    trace = MemSnoop.trace(pid)

    # Save the trace.
    name, _ =  splitext(test)
    MemSnoop.save("$test.jls", trace)
    plt = plot(trace)

    savefig("$test.png")
    MemSnoop.save("$name.trace", trace) 
end


