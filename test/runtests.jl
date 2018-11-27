using MemSnoop
using Test
using Combinatorics
using BenchmarkTools

MemSnoop.enable_hugepages(MemSnoop.Never)

# Testing String prinng
println(MemSnoop.Always)
println(MemSnoop.MAdvise)
println(MemSnoop.Never)

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

include("vma.jl")
include("util.jl")
include("trace.jl")
include("timing.jl")

# Include tests
include("programs.jl")
