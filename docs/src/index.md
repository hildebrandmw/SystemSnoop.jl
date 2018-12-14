# MemSnoop

Idle page tracking for memory analysis of running applications.

## Security Warning

This package requires running `julia` as root because it needs access to several protected
kernel files. To minimize your risk, I tried minimize the number of third party non-stdlib 
dependencies. The only third party non-test dependency of this package is 
[PAPI](https://github.com/hildebrandmw/PAPI.jl), which I also developed. That package 
depends on [Binary Provider](https://github.com/JuliaPackaging/BinaryProvider.jl), but only
for building. Use this package at your own risk.

## Usage

The bread and buffer of this package is the [`trace`](@ref) function. This function takes 
a [`SnoopedProcess`](@ref) and a NamedTuple of [`AbstractMeasurement`](@ref)s. For example,
suppose we wanted to measure some metrics about the current Julia process. We would then
do something like this:

```julia
julia> using MemSnoop

# Get an unpauseable process. If we made a pausable process, then we would pause
# the system that's doing the measuring, and that would be a problem.
julia> process = SnoopedProcess{Unpausable}(getpid())

# Get a list of measurements we want to take. In this example, for each measurement we 
# perform an initial timestamp, monitor disk io, read the assigned and resident memory, 
# and take a final measurement
julia> measurements = (
    initial = MemSnoop.Timestamp(),
    disk = MemSnoop.DiskIO(),
    memory = MemSnoop.Statm(),
    final = MemSnoop.Timestamp(),
)

# Then, we perform a series of measurements.
julia> data = trace(process, measurements; sampletime = 1, iter = 1:3);

# The resulting `data` is a named tuple with the same names as `measurements`. The values
# themselves are the corresponding measurements.
julia> data.initial
3-element Array{Dates.DateTime,1}:
 2018-12-13T15:58:19.872
 2018-12-13T15:58:20.874
 2018-12-13T15:58:21.876

julia> data.disk
3-element Array{NamedTuple{(:rchar, :wchar, :readbytes, :writebytes),NTuple{4,Int64}},1}:
 (rchar = 11241089, wchar = 3461495, readbytes = 0, writebytes = 1085440)
 (rchar = 11241236, wchar = 3461495, readbytes = 0, writebytes = 1085440)
 (rchar = 11241383, wchar = 3461495, readbytes = 0, writebytes = 1085440)

julia> data.memory
3-element Array{NamedTuple{(:size, :resident),Tuple{Int64,Int64}},1}:
 (size = 318312, resident = 72959)
 (size = 318312, resident = 72959)
 (size = 318312, resident = 72959)

julia> data.final
3-element Array{Dates.DateTime,1}:
 2018-12-13T15:58:19.872
 2018-12-13T15:58:20.874
 2018-12-13T15:58:21.876
```

One of the most powerful measurement types is [Idle Page Tracking](@ref), though this 
measurement requires Julia to be run as `sudo` to work.

## Obtaining Process PIDs

Currently, you have to obtain the `pid` for a process manually. However, in Julia 1.1, you
will be able to obtain the `pid` of a process launched by Julia. This feature will be
incorporated into this package once Julia 1.1 is released.
