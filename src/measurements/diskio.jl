"""
Read from `/proc/diskstats` for a set of devices.  Return a `Dict{Symbol,DiskStats}` where
the keys are the devices being measured and the values are [`DiskStats`](@ref) for each
device.

Fields
------
* `devices::Vector{String}` - Names of devices for which to take measurements.

Constructor
-----------
```
SystemSnoop.DiskIO(devices) -> DiskIO
```

Documentation on `/proc/diskstats`
----------------------------------
The /proc/diskstats file displays the I/O statistics
of block devices. Each line contains the following 14
fields:

     1 - major number
     2 - minor mumber
     3 - device name
     4 - reads completed successfully
     5 - reads merged
     6 - sectors read
     7 - time spent reading (ms)
     8 - writes completed
     9 - writes merged
    10 - sectors written
    11 - time spent writing (ms)
    12 - I/Os currently in progress
    13 - time spent doing I/Os (ms)
    14 - weighted time spent doing I/Os (ms)

Kernel 4.18+ appends four more fields for discard
tracking putting the total at 18:

    15 - discards completed successfully
    16 - discards merged
    17 - sectors discarded
    18 - time spent discarding
"""
struct DiskIO
    devices::Vector{String}
end

Measurements.prepare(::DiskIO, args...) = Vector{Dict{Symbol,DiskStats}}()
Measurements.measure(D::DiskIO) = diskstats(D.devices)

#####
##### Implementation details
#####

"""
Storate for [`DiskIO`](@ref).

Fields
------

* `reads_completed` - Reads successfully completed
* `reads_merged`
* `sectors_read`
* `time_reading` (units: `ms`). Note that this field is for all pending operations, and will
    add time for multiple read requests.
* `writes_completed`
* `writes_merged`
* `sectors_written`
* `time_writing` (units: `ms`). Note that this field is for all pending operations, and will
    add time for multiple read requests.
* `time_io` (units: `ms`). Note, this is wall for the total time this disk was busy.
"""
struct DiskStats
    reads_completed::Int64
    reads_merged::Int64
    sectors_read::Int64
    time_reading::Int64
    writes_completed::Int64
    writes_merged::Int64
    sectors_written::Int64
    time_writing::Int64
    time_io::Int64
end

function diskstats(devices::Vector{String})
    stats = Dict{Symbol,DiskStats}()
    open("/proc/diskstats") do f
        for ln in eachline(f)
            splits = split(ln)
            # Check if this field is one we want.
            device = splits[3]
            if in(device, devices)
                # Extract and parse the fields of interest
                vals = safeparse.(Int64, getindex.(Ref(splits), (4, 5, 6, 7, 8, 9, 10, 11, 13)))
                diskstats = DiskStats(vals...)
                stats[Symbol(device)] = diskstats
            end
        end
    end

    return stats
end
