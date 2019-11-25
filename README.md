# SystemSnoop

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] [![][lifecycle-img]][lifecycle-url] [![][codecov-img]][codecov-url] |

Base API for unifying the collection of data for computer systems monitoring purposes.
This is particularly useful when writing measurement to gather either system wide metrics (such as DRAM bandwidth, total number of L3 cache hits etc.) or process specific metrics (CPU usage, memory usge etc.)

For a measurement of Julia type `T`, SystemSnoop requires the implementation of a single method
```julia
SystemSnoop.measure(x::T, [kw]) where {T}
```
to be compatible, where `kw` is an optional `NamedTuple` if the measurement requires additional external arguments (described below).
When called, `measure(x)` should return a measurement value when called.

## Snoop Function

The main exported function for this module is
```julia
snoop(f, measurements::NamedTuple, [process = GlobalProcess()]; kw...) -> trace
```
where
* `f` is a function that accepts a single argument of type `SystemSnoop.Snooper` (discussed below)
* `measurements` is a `NamedTuple` where each **value** in the `NamedTuple` implements the SystemSnoop API.
* `process` is an `AbstractProcess`.
* `kw...` is a collection of keyword arguments that will be converted to a `NamedTuple` and forwared as a second positional argument to the SystemSnoop API functions.

### Return Value

The function `snoop` will return a trace in the form of a [`StructArray`](https://github.com/JuliaArrays/StructArrays.jl).
The **propertynames** of the trace are the same as the property names of `measurements`.
That is:
```
propertynames(trace) == propertynames(measurements)
```
The rows of trace correspond to subsequent calls of `measure!` on the `SystemSnoop.Snooper` type.

Additionally, if the function `f` returns a value, then `snoop` will return a tuple `(trace, val)` where `val` is the return value of `f`.
See the examples below for more detail.

### `SystemSnoop.Snooper`

The `Snooper` is an opaque type with two methods:

```julia
measure!(::Snooper)
```
Which calls `SystemSnoop.measure` on each measurement and appends this result to the current `trace`.

```julia
postprocess(::Snooper) -> NamedTuple
```
Call `postprocess` on each measurement, flatten the results into a NamedTuple (see detailed example below).

## Snoop API

The Snoop API is broken into one mandatory function and three optional functions.
Each of these function can optionally accept a second positional argument `kw::NamedTuple` corresponding to the keyword arguments of `snoop`.

### Mandatory
```julia
SystemSnoop.measure(x::T, [kw]) where {T}
```
Return a measurement value.

### Optional

```julia
SystemSnoop.prepare(x::T, [kw]) where {T}
```
Perform any steps necessary to prepare measurement `x`. 
Called once before any measurements are taken.

```julia
SystemSnoop.cleanup(x::T, [kw]) where {T}
```
Perform any cleanup steps necessary for measurement `x`.
Called once just before `snoop` returns.

```julia
SystemSnoop.postprocess(x::T, v, [kw]) where {T} -> NamedTuple
```
Perform any post processing for measurement `x`.
Argument `v` is the vector of measurements taken by `x`.
Result must be a `NamedTuple` with any names.

## Simple Example

A simple example of using SystemSnoop is shown below.
```julia
using SystemSnoop

# Use a Dummy Measurement to show some of the API
mutable struct DummyMeasurement
    count::Int
end

# Print out a message when `prepare` is called
SystemSnoop.prepare(d::DummyMeasurement, kw) = println("Prepare Dummy Measurements: kw = ", kw)

# Increment the count according to the keyword argument `increment` and return
function SystemSnoop.measure(d::DummyMeasurement, kw)
    d.count += kw.increment
    return d.count
end

# Now, we construct a list of measurements to take in a `NamedTuple` to pass to `snoop`.
measurements = (
    timestamp = SystemSnoop.Timestamp(),
    dummy = DummyMeasurement(0),
)

trace = snoop(measurements; increment = 10) do snooper
    for _ in 1:5
        sleep(1)
        measure!(snooper)
    end
end

# Show the results of the trace.
display(trace)
# 5-element StructArray(::Array{Dates.DateTime,1}, ::Array{Int64,1}) with eltype NamedTuple{(:timestamp, :dummy),Tuple{Dates.DateTime,Int64}}:
#  (timestamp = 2019-11-25T11:55:40.699, dummy = 10)
#  (timestamp = 2019-11-25T11:55:41.701, dummy = 20)
#  (timestamp = 2019-11-25T11:55:42.703, dummy = 30)
#  (timestamp = 2019-11-25T11:55:43.705, dummy = 40)
#  (timestamp = 2019-11-25T11:55:44.707, dummy = 50)

# Since the result is a `StructArray`, we can access it either through fields or by index:
display(trace.timetamp)
# 5-element Array{Dates.DateTime,1}:
#  2019-11-25T11:55:40.699
#  2019-11-25T11:55:41.701
#  2019-11-25T11:55:42.703
#  2019-11-25T11:55:43.705
#  2019-11-25T11:55:44.707

display(trace.dummy)
# 5-element Array{Int64,1}:
#  10
#  20
#  30
#  40
#  50

display(trace[2])
# (timestamp = 2019-11-25T11:55:41.701, dummy = 20)
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
measurements = (
    statm = Statm(),
)

trace = SystemSnoop.snoop(measurements) do snooper
    # Perform some baseline measurements 
    for _ in 1:5
        SystemSnoop.measure!(snooper)
        sleep(0.1)
    end

    # Now, allocate a huge array
    x = Vector{Float32}(undef, 250_000_000)

    # Take some more samples
    for _ in 1:5
        SystemSnoop.measure!(snooper)
        sleep(0.1)
    end

    # Finally, write to `x` to ensure that its memory is actually allocated by the OS
    x .= one(eltype(x))

    # Take some more samples
    for _ in 1:5
        SystemSnoop.measure!(snooper)
        sleep(0.1)
    end
end

using UnicodePlots

lineplot(trace.statm; xlim = (0, 15), border = :ascii, canvas = AsciiCanvas)
```
for which we see the output (if running in a fresh Julia session)
```
              +----------------------------------------+
   1300000000 |                             .__________|
              |                             |          |
              |                            .`          |
              |                            |           |
              |                            /           |
              |                            |           |
              |                            |           |
              |                           .`           |
              |                           |            |
              |                           /            |
              |                           |            |
              |                           |            |
              |                          .`            |
              |                          |             |
    200000000 |  """""""""""""\-----------             |
              +----------------------------------------+
              0                                       15
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

function SystemSnoop.postprocess(::Statm, trace)
    return (
        virtual = getproperty.(trace, :virtual),
        resident = getproperty.(trace, :resident),
    )
end

measurements = (
    statm = Statm(),
)

trace, post = SystemSnoop.snoop(measurements) do snooper
    # Perform some baseline measurements 
    for _ in 1:5
        SystemSnoop.measure!(snooper)
        sleep(0.1)
    end

    # Now, allocate a huge array
    x = Vector{Float32}(undef, 250_000_000)

    # Take some more samples
    for _ in 1:5
        SystemSnoop.measure!(snooper)
        sleep(0.1)
    end

    # Finally, write to `x` to ensure that its memory is actually allocated by the OS
    x .= one(eltype(x))

    # Take some more samples
    for _ in 1:5
        SystemSnoop.measure!(snooper)
        sleep(0.1)
    end
    return SystemSnoop.postprocess(snooper)
end

plt = lineplot(
      post.virtual; 
      xlim = (0, 15), 
      ylim = (0, 1.05 * maximum(post.virtual)), 
      border = :ascii, 
      canvas = AsciiCanvas
)
lineplot!(plt, post.resident)
```
Which generates the following plot
```
              +----------------------------------------+
   1910479872 |               .________________________|
              |               .                        |
              |               |                        |
              |              .`                        |
              |              .                         |
              |              |              |""""""""""|
              |             .`             |           |
              |             .              |           |
              |  \----------/              |           |
              |                           |            |
              |                           |            |
              |                           |            |
              |  ._______________________]             |
              |                                        |
            0 |                                        |
              +----------------------------------------+
              0                                       15
```

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://hildebrandmw.github.io/SystemSnoop.jl/latest

[lifecycle-img]: https://img.shields.io/badge/lifecycle-maturing-blue.svg
[lifecycle-url]: https://www.tidyverse.org/lifecycle/

[travis-img]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl.svg?branch=master
[travis-url]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl

[codecov-img]: https://codecov.io/gh/hildebrandmw/SystemSnoop.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/hildebrandmw/SystemSnoop.jl
