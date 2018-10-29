using MemSnoop
using Test

# Set up some variables for running the test programs.
TESTDIR = @__DIR__
DEPSDIR = joinpath(TESTDIR, "deps")
BUILDDIR = joinpath(DEPSDIR, "build")

# Compile the test programs
include(joinpath(DEPSDIR, "build.jl"))

# Include tests
include("programs.jl")
