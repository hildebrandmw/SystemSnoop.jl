# MemSnoop

Idle page tracking for memory analysis of running applications.

## Security Warning

This package requires running `julia` as root because it needs access to several protected
kernel files. To minimize your risk, this package's only dependency is the `Serialization`
standard library. However, use this package at your own risk.

## Generating a Trace

Tracking a process is easy, simply call [`trace`](@ref)

```@docs
MemSnoop.trace
```

The [`trace`](@ref) function returns a [`Vector{Sample}`](@ref Sample). Each 
[`Sample`](@ref) contains 

* The [`VMA`](@ref)s assigned to the process for that sample interval.
* The virtual page numbers of pages that were active during that sample interval. 
    Internally, these are stored as a [`SortedRangeVector`](@ref) for compression.

## Performing Analysis

Because of the dependency restriction, only basic functionality is provided in the MemSnoop
package itself. For more detailed analyses that can be performed after a trace is generated,
use the package [SnoopAnalyzer](https://github.com/hildebrandmw/SnoopAnalyzer.jl). 
Eventually, this package will also be documented here.
