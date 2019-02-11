"""
Record the uptime metrics of a process.

TODO: Document
"""
struct Uptime end

struct UptimeStruct
    system_uptime::Float64
    minflt::Int64
    majflt::Int64
    utime::Int64
    stime::Int64
    cutime::Int64
    cstime::Int64
    starttime::Int64
    blkio_ticks::Int64
end

Measurements.prepare(U::Uptime, args...) = Vector{UptimeStruct}()

function Measurements.measure(U::Uptime, process)::UptimeStruct
    # Get the utime from /proc/uptime
    system_uptime = open("/proc/uptime") do f
        safeparse(Float64, readuntil(f, ' '))
    end

    # Get the rest of the stats from /proc/[pid]/stat
    pid = getpid(process) 
    stats = pidsafeopen("/proc/$pid/stat", pid) do f
        vals = split(read(f, String))

        # Pick out the fields we want
        parsed_vals = safeparse.(Int64, getindex.(Ref(vals), (10, 12, 14, 15, 16, 17, 22, 42)))

        return UptimeStruct(system_uptime, parsed_vals...)
    end

    return stats
end
