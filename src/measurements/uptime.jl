struct Uptime <: AbstractMeasurement end

const UptimeTuple = NamedTuple{
    (:system_uptime, :minflt, :majflt, :utime, :stime, :cutime, :cstime, :starttime),
    Tuple{Float64, Int64, Int64, Int64, Int64, Int64, Int64, Int64}
}

prepare(U::Uptime, args...) = Vector{UptimeTuple}()

function measure(U::Uptime, process)::UptimeTuple
    # Get the utime from /proc/uptime
    system_uptime = open("/proc/uptime") do f
        safeparse(Float64, readuntil(f, ' '))
    end

    # Get the rest of the stats from /proc/[pid]/stat
    pid = getpid(process) 
    stats = pidsafeopen("/proc/$pid/stat", pid) do f
        vals = split(read(f, String))

        # Pick out the fields we want
        parsed_vals = safeparse.(Int64, getindex.(Ref(vals), (10, 12, 14, 15, 16, 17, 22)))

        return (
            system_uptime = system_uptime,
            minflt = parsed_vals[1],
            majflt = parsed_vals[2],
            utime = parsed_vals[3],
            stime = parsed_vals[4],
            cutime = parsed_vals[5],
            cstime = parsed_vals[6],
            starttime = parsed_vals[7]
        )
    end

    return stats
end
