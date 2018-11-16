# Declare the tests to run
tests = ("single", "double")

using MemSnoop

# Compile the C++ tests
include("build.jl")
builddir = build(tests)

# Launch a test
fullpath = joinpath(builddir, "double")
pid, process, pipe = MemSnoop.launch(fullpath)
trace = MemSnoop.trace(pid; sampletime = 1)
