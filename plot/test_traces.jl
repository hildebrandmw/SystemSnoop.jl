# Run the sample workloads and save the traces to the working directory for later plotting.
tests = ("single.out", "double.out")

using MemSnoop

# Resolve path to the compiled test files.
PKGDIR = dirname(@__DIR__)
DEPSDIR = joinpath(PKGDIR, "deps")
BUILDDIR = joinpath(DEPSDIR, "build")

for test in tests
    @info "Running workload: $test"
    fullpath = joinpath(BUILDDIR, test)
    pid, process, pipe = MemSnoop.launch(fullpath)
    trace = MemSnoop.snoop(pid)

    # Save the trace.
    name, _ =  splitext(test)
    MemSnoop.save("$name.trace", trace) 
end
