"""
Record the `size` and `resident` fields of `/proc/[pid]/statm`.

Each measurement returns a `NamedTuple` with names `size` and `resident`.

From the man page:
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
"""
struct Statm <: AbstractMeasurement end

const StatmTuple = NamedTuple{(:size, :resident), Tuple{Int,Int}}

prepare(::Statm, args...) = Vector{StatmTuple}()

function measure(S::Statm, process)::StatmTuple
    pid = getpid(process)
    stats = pidsafeopen("/proc/$pid/statm", pid) do f
        
        size = safeparse(Int, readuntil(f, ' '))
        resident = safeparse(Int, readuntil(f, ' '))

        return (size = size, resident = resident)
    end
    return stats
end
