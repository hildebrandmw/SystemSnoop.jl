# Distance / WSS

To perform an analysis to estimate the Working Set Size (WSS) of an application, as well
as the Memory Reuse Distance of pages, use the [`MemSnoop.track_distance`](@ref) function.

```@docs
MemSnoop.track_distance
MemSnoop.DistanceTracker
```

## BucketStack

A custom [`MemSnoop.BucketStack`](@ref) type is used to perform the stack analysis to estimate
page Reuse Distance.

```@docs
MemSnoop.BucketStack
MemSnoop.upstack!
```
