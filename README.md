# SystemSnoop

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] [![][lifecycle-img]][lifecycle-url] [![][codecov-img]][codecov-url] |

Base API for unifying the collection of data for computer systems monitoring purposes.
This is particularly useful when writing measurement to gather either system wide metrics (such as DRAM bandwidth, total number of L3 cache hits etc.) or process specific metrics (CPU usage, memory usge etc.)

For a measurement of Julia type `T`, SystemSnoop requires the implementation of a single method
```julia
SystemSnoop.measure(x::T) where {T}
```
to be compatible.
When called, `measure(x)` should return a measurement value when called.

## Snooped Macro

The main export for this module is
```julia
trace = @snooped measurement(s) sampletime expr
```
which takes measurements from `measurement(s)` every `sampletime` while concurrently running `expr`. 

If `sampletime` is an `Integer`, then it is interpreted as milliseconds, and so `@snooped x 500 sleep(10)` will measure `x` every 500 milliseconds.
Alternative, `sampletime` can be an arbitrary `Dates.TimePeriod`.

Argument `measurement(s)` can either be in instance of type `T` that implements `SystemSnoop.measure`, or a `NamedTuple` of such types.
If `measurement` is just a single object, then `trace` will be a `Vector` of measurements.
If `measurements` is a `NamedTuple`, then `trace` will be a [`StructArray`](https://github.com/JuliaArrays/StructArrays.jl) of measurements.
The **propertynames** of the trace are the same as the property names of `measurements`.
That is:
```
propertynames(trace) == propertynames(measurements)
```

## Snoop API

The Snoop API is broken into one mandatory function and three optional functions.
Each of these function can optionally accept a second positional argument `kw::NamedTuple` corresponding to the keyword arguments of `snoop`.

### Mandatory
```julia
SystemSnoop.measure(x::T) where {T}
```
Return a measurement value.

### Optional

```julia
SystemSnoop.prepare(x::T) where {T}
```
Perform any steps necessary to prepare measurement `x`. 
Called once before any measurements are taken.

```julia
SystemSnoop.clean(x::T) where {T}
```
Perform any cleanup steps necessary for measurement `x`.
Called once just before `snoop` returns.

## Simple Example

A simple example of using SystemSnoop is shown below.
```julia
using SystemSnoop

# Use a Dummy Measurement to show some of the API
mutable struct DummyMeasurement
    count::Int
end

# Print out a message when `prepare` is called
SystemSnoop.prepare(d::DummyMeasurement) = println("Prepare Dummy Measurements")

# Increment the count according to the keyword argument `increment` and return
function SystemSnoop.measure(d::DummyMeasurement)
    d.count += 1
    return d.count
end

# Now, we construct a list of measurements to take in a `NamedTuple` to pass to `@snooped`.
measurements = (
    timestamp = SystemSnoop.Timestamp(),
    dummy = DummyMeasurement(0),
)

# Sample every 1000 milliseconds
trace = @snooped measurements 1000 sleep(5)

# Show the results of the trace.
display(trace)
# 5-element StructArray(::Array{Dates.DateTime,1}, ::Array{Int64,1}) with eltype NamedTuple{(:timestamp, :dummy),Tuple{Dates.DateTime,Int64}}:
#  (timestamp = 2020-06-25T11:25:55.075, dummy = 1)
#  (timestamp = 2020-06-25T11:25:56.075, dummy = 2)
#  (timestamp = 2020-06-25T11:25:57.075, dummy = 3)
#  (timestamp = 2020-06-25T11:25:58.075, dummy = 4)
#  (timestamp = 2020-06-25T11:25:59.075, dummy = 5)

# Since the result is a `StructArray`, we can access it either through fields or by index:
display(trace.timetamp)
# 5-element Array{Dates.DateTime,1}:
#  2020-06-25T11:25:55.075
#  2020-06-25T11:25:56.075
#  2020-06-25T11:25:57.075
#  2020-06-25T11:25:58.075
#  2020-06-25T11:25:59.075

display(trace.dummy)
# 5-element Array{Int64,1}:
#  1
#  2
#  3
#  4
#  5

display(trace[2])
# (timestamp = 2020-06-25T11:25:56.075, dummy = 2)
```
We also don't necessarily need to construct a `NamedTuple` of measurements.
```julia
using Dates
sampletime = Dates.Millisecond(10)
x = DummyMeasurement(0)
trace = @snooped x sampletime sleep(0.1)

display(trace)
# 10-element Array{Int64,1}:
#   1
#   2
#   3
#   4
#   5
#   6
#   7
#   8
#   9
#  10
```

## Detailed Example

Suppose we wanted to measure the total resident memory of the Julia process over time.
On Linux, this accessed using `/proc/[pid]/statm`.
From the `proc` manpage:
```
/proc/[pid]/statm
      Provides information about memory usage, measured in pages.  The columns are:

          size       (1) total program size
                     (same as VmSize in /proc/[pid]/status)
          resident   (2) resident set size
                     (same as VmRSS in /proc/[pid]/status)
          shared     (3) number of resident shared pages (i.e., backed by a file)
                     (same as RssFile+RssShmem in /proc/[pid]/status)
          text       (4) text (code)
          lib        (5) library (unused since Linux 2.6; always 0)
          data       (6) data + stack
          dt         (7) dirty pages (unused since Linux 2.6; always 0)
```
To do this, we just need to define the following:
```julia
using SystemSnoop

struct Statm end

function SystemSnoop.measure(::Statm)
    # Get the `pid` for the currently running process
    pid = getpid()

    # Size of a page of memory
    pagesize = 4096
    return open("/proc/$pid/statm") do f
        # Skip the first field
        _ = readuntil(f, ' ')

        # We're now at the `resident` field - parse this field as an `Int`
        resident = parse(Int, readuntil(f, ' '))
        return pagesize * resident
    end
end
```
Now, we can test if this works
```julia
trace = @snooped Statm() 500 begin
    # Sleep for a little bit
    sleep(2)

    # Now, allocate a large array
    x = Vector{Float32}(undef, 250_000_000)

    # sleep again
    sleep(2)

    # Finally, write to `x` to ensure that its memory is actually allocated by the OS
    x .= one(eltype(x))

    # sleep to get more samples
    sleep(2)
end

using UnicodePlots

lineplot(trace; xlim = (0, 15), border = :ascii, canvas = AsciiCanvas)
```
for which we see the output (if running in a fresh Julia session)
```
                  +----------------------------------------+
   1.4246346752e9 |                                        |
                  |                        ,---------------|
                  |                        /               |
                  |                       ,`               |
                  |                       .                |
                  |                       |                |
                  |                      .`                |
                  |                      |                 |
                  |                      |                 |
                  |                      |                 |
                  |                     ,`                 |
                  |   __________________/                  |
                  |                                        |
                  |                                        |
                0 |                                        |
                  +----------------------------------------+
                  0                                       13
```

### Explanation

The constructor `Vector{Float32}(undef, dims...)` (eventually) goes through a normal call `malloc`.
But since the memory does not need to be initialized (`undef`), the OS simply notes that our Julia process requested around 1 GB of virtual memory, but hasn't set up the virtual to physical page mappings.
Once the array is initialized by writing to it, the OS setups up the page mapping and we see that the resident memory increases.

### Verification

We can verify this using a simple post processing routine and a modification to our `measure` function.
```julia
using SystemSnoop, UnicodePlots

struct Statm end

function SystemSnoop.measure(::Statm)
    # Get the `pid` for the currently running process
    pid = getpid()

    # Size of a page of memory
    pagesize = 4096
    return open("/proc/$pid/statm") do f
        # Now, read the virtual memory size as well
        virtual = parse(Int, readuntil(f, ' '))

        # We're now at the `resident` field - parse this field as an `Int`
        resident = parse(Int, readuntil(f, ' '))
        return (
            virtual = pagesize * virtual,
            resident = pagesize * resident
        )
    end
end

measurements = (
    statm = Statm(),
)

trace = @snooped Statm() 500 begin
    # Sleep for a little bit
    sleep(2)

    # Now, allocate a large array
    x = Vector{Float32}(undef, 250_000_000)

    # sleep again
    sleep(2)

    # Finally, write to `x` to ensure that its memory is actually allocated by the OS
    x .= one(eltype(x))

    # sleep to get more samples
    sleep(2)
end

virtual = getproperty.(trace, :virtual)
resident = getproperty.(trace, :resident)

plt = lineplot(
      virtual; 
      xlim = (0, length(trace)), 
      ylim = (0, 1.05 * maximum(virtual)), 
      border = :ascii, 
      canvas = AsciiCanvas
)
lineplot!(plt, resident)
```
Which generates the following plot
```
                        +----------------------------------------+
   1.9901607936000001e9 |            ____________________________|
                        |           ,`                           |
                        |           /                            |
                        |          .`                            |
                        |          .                             |
                        |          /             /"""""""""""""""|
                        |         ,`            .`               |
                        |         |             .                |
                        |   """"""`             /                |
                        |                      ,`                |
                        |                      |                 |
                        |                     .`                 |
                        |   __________________/                  |
                        |                                        |
                      0 |                                        |
                        +----------------------------------------+
                        0                                       13
```

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://hildebrandmw.github.io/SystemSnoop.jl/latest

[lifecycle-img]: https://img.shields.io/badge/lifecycle-maturing-blue.svg
[lifecycle-url]: https://www.tidyverse.org/lifecycle/

[travis-img]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl.svg?branch=master
[travis-url]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl

[codecov-img]: https://codecov.io/gh/hildebrandmw/SystemSnoop.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/hildebrandmw/SystemSnoop.jl
