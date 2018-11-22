# Generating Traces

MemSnoop has the ability to record the full trace of pages accessed by an application. This
is performed using [`trace`](@ref)

```@docs
MemSnoop.trace
MemSnoop.pages(::Vector{MemSnoop.Sample})
MemSnoop.vmas(::Vector{MemSnoop.Sample})
```



## Implementation Details - Sample

```@docs
MemSnoop.Sample
MemSnoop.isactive(::MemSnoop.Sample, ::Any)
MemSnoop.pages(::MemSnoop.Sample)
MemSnoop.bitmap(::Vector{MemSnoop.Sample}, ::MemSnoop.VMA)
```

## Implementation Details - SortedRangeVector

Since pages are generally accessed sequentially, the record of active pages is encoded as
a [`MemSnoop.SortedRangeVector`](@ref) that compresses contiguous runs of accesses. Note that 
there is an implicit assumption that the VMAs are ordered, which should be the case since 
`/prod/pid/maps` orderes VMAs.

```@docs
MemSnoop.SortedRangeVector
MemSnoop.lastelement
push!(::MemSnoop.SortedRangeVector{T}, x::T) where T
MemSnoop.insorted
```

