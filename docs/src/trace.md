# Full Trace

MemSnoop has the ability to record the full trace of pages accessed by an application. This
is performed using [`trace`]

```@docs
MemSnoop.trace
MemSnoop.Trace
MemSnoop.pages(::MemSnoop.Trace)
```

## Implementation Details - RangeVector

Since pages are generally accessed sequentially, the record of active pages is encoded as
a [`MemSnoop.RangeVector`](@ref) that compresses contiguous runs of accesses. Note that 
there is an implicit assumption that the VMAs are ordered, which should be the case since 
`/prod/pid/maps` orderes VMAs.

```@docs
MemSnoop.RangeVector
MemSnoop.lastelement
push!(::MemSnoop.RangeVector{T}, x::T) where T
MemSnoop.insorted
```

## Implementation Details - Sample

```@docs
MemSnoop.Sample
MemSnoop.isactive(::MemSnoop.Sample, ::Any)
MemSnoop.pages(::MemSnoop.Sample)
```

## Plotting

For generating plots, the [`MemSnoop.ArrayView`](@ref) type is provided, which lazily 
wraps the `trace` type and can produce a boolean map of addresses hit. General usage looks 
something like

```julia
using Plots

heatmap(ArrayView(trace))
```

```@docs
MemSnoop.ArrayView
```
