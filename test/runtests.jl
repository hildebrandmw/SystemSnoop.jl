using MemSnoop
using Test
using Combinatorics
using BenchmarkTools

MemSnoop.enable_hugepages(MemSnoop.Never)

# Set up some variables for running the test programs.
TESTDIR = @__DIR__
DEPSDIR = joinpath(TESTDIR, "deps")
BUILDDIR = joinpath(DEPSDIR, "build")

# Compile the test programs
include(joinpath(DEPSDIR, "build.jl"))

include("vma.jl")
include("util.jl")
include("trace.jl")
include("timing.jl")

# Include tests
include("programs.jl")
