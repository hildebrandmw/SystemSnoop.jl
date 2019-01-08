# SystemSnoop

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
julia> using SystemSnoop

# Procide the command we would like to run
julia> process = `top`

# Get a list of measurements we want to take. In this example, for each measurement we 
# perform an initial timestamp, monitor disk io, read the assigned and resident memory, 
# and take a final measurement
julia> measurements = (
    initial = SystemSnoop.Timestamp(),
    disk = SystemSnoop.DiskIO(),
    memory = SystemSnoop.Statm(),
    final = SystemSnoop.Timestamp(),
)

# Then, we perform a series of measurements.
julia> data = trace(command, measurements; sampletime = 1, iter = 1:3);

# The resulting `data` is a named tuple with the same names as `measurements`. The values
# themselves are the corresponding measurements.
julia> data.initial
3-element Array{Dates.DateTime,1}:
 2019-01-03T16:57:39.064
 2019-01-03T16:57:40.067
 2019-01-03T16:57:41.069

julia> data.disk
3-element Array{NamedTuple{(:rchar, :wchar, :readbytes, :writebytes),NTuple{4,Int64}},1}:
 (rchar = 1948, wchar = 0, readbytes = 0, writebytes = 0)
 (rchar = 1948, wchar = 0, readbytes = 0, writebytes = 0)
 (rchar = 1948, wchar = 0, readbytes = 0, writebytes = 0)

julia> data.memory
3-element Array{NamedTuple{(:size, :resident),Tuple{Int64,Int64}},1}:
 (size = 1544, resident = 191)
 (size = 1544, resident = 191)
 (size = 1544, resident = 191)

julia> data.final
3-element Array{Dates.DateTime,1}:
 2019-01-03T16:57:39.065
 2019-01-03T16:57:40.067
 2019-01-03T16:57:41.069
```

One of the most powerful measurement types is [Idle Page Tracking](@ref), though this 
measurement requires Julia to be run as `sudo` to work.
