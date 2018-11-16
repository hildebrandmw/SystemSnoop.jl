# Full Traces

MemSnoop has the ability to record the full trace of pages accessed by an application. This
is performed using [`trace`](@ref)

```@docs
MemSnoop.trace
```



## Implementation Details - Sample

```@docs
MemSnoop.Sample
MemSnoop.isactive(::MemSnoop.Sample, ::Any)
MemSnoop.pages
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

