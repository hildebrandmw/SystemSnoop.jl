using SystemSnoop
using Test
using Combinatorics
using BenchmarkTools

SystemSnoop.enable_hugepages(SystemSnoop.Never)

# Testing String prinng
println(SystemSnoop.Always)
println(SystemSnoop.MAdvise)
println(SystemSnoop.Never)

# Set up some variables for running the test programs.
TESTDIR = @__DIR__

#####
##### Include and build the test package
#####

include(joinpath("SnoopTest", "src", "SnoopTest.jl"))
using .SnoopTest
SnoopTest.build()

#####
##### Test Suits
#####

# Core functionality
include("util.jl")
include("rangevector.jl")

# idle page tracking
include("idlepages/vma.jl")
include("idlepages/idlepages.jl")
include("idlepages/timing.jl")

# trace function
include("trace.jl")

# Larger tests
include("programs.jl")

# Test analysis
include("analysis/reusedistance.jl")
