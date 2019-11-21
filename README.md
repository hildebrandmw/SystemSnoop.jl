# SystemSnoop

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] ![][lifecycle-img] [![][codecov-img]][codecov-url] |

Base API for unifying the collection of data for computer systems monitoring purposes.
This is particularly useful when writing measurement to gather either system wide metrics (such as DRAM bandwidth, total number of L3 cache hits etc.) or process specific metrics (CPU usage, memory usge etc.)

For a measurement of Julia type `T`, SystemSnoop requires the implementation of a single method
```julia
SystemSnoop.measure(x::T, [kw]) where {T}
```
to be compatible, where `kw` is an optional `NamedTuple` if the measurement requires additional external arguments (described below).
When called, `measure(x)` should return a measurement value when called.

# Example

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

lineplot(trace.statm; xlim = (0, 15))
```
for which we see the output (if running in a fresh Julia session)
```
              ┌────────────────────────────────────────┐
   1300000000 │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠤⠤⠤⠤⠤⠤⠤⠤⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
    200000000 │⠀⠀⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
              └────────────────────────────────────────┘
              0                                       20
```

### Explanation

The constructor `Vector{Float32}(undef, dims...)` (eventually) goes through a normal call `malloc`.
But since the memory does not need to be initialized (`undef`), the OS simply notes that our Julia process requested around 1 GB of virtual memory, but hasn't set up the virtual to physical page mappings.
Once the array is initialized by writing to it, the OS setups up the page mapping and we see that the resident memory increases.

### Verification

We can verify this using a simple post processing routine and a modification to our `measure` function.
```
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

plt = lineplot(post.virtual; xlim = (0, 15), ylim = (0, 1.05 * maximum(post.virtual)))
lineplot!(plt, post.resident)
```
Which generates the following plot
```
                  ┌────────────────────────────────────────┐
   1.9099379712e9 │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡏⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠠⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                0 │⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│
                  └────────────────────────────────────────┘
                  0                                       15
```

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://hildebrandmw.github.io/SystemSnoop.jl/latest

[lifecycle-img]: https://img.shields.io/badge/lifecycle-experimental-orange.svg

[travis-img]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl.svg?branch=master
[travis-url]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl

[codecov-img]: https://codecov.io/gh/hildebrandmw/SystemSnoop.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/hildebrandmw/SystemSnoop.jl
