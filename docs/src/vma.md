# VMAs

Internally, MemSnoop works on VMA boundaries, allowing for filtering on VMAs, and
for merging overlapping VMAs together. The latter is important when aggregating 
data across multiple samples, as various VMAs may change in size from sample
to sample.

## Type
```@docs
MemSnoop.VMA
```

## Methods

### Basic Functions

```@docs
MemSnoop.startaddress(::MemSnoop.VMA)
MemSnoop.stopaddress(::MemSnoop.VMA)
MemSnoop.length(::MemSnoop.VMA)
```

### Set-like Functions

```@docs
MemSnoop.overlapping
issubset(::MemSnoop.VMA, ::MemSnoop.VMA)
union(::MemSnoop.VMA, ::MemSnoop.VMA)
MemSnoop.compact
```

## Filters

Filters can be applied to VMAs to prune cut down on the amount of data collected. 
Built-in filters are described below.

```@docs
MemSnoop.heap
MemSnoop.readable
MemSnoop.writable
MemSnoop.executable
MemSnoop.flagset
MemSnoop.longerthan
```
