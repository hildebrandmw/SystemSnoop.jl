# Measure the bytes read and written by a process
struct DiskIO <: AbstractMeasurement end

const BytesIO = NamedTuple{(:read, :write), Tuple{Int64, Int64}}
# Values are tuples
prepare(::DiskIO) = Vector{BytesIO}()

#=
Example Read from /proc/pid/io:

```
rchar: 3089822
wchar: 139463
syscr: 159
syscw: 178
read_bytes: 0
write_bytes: 4096
cancelled_write_bytes: 0
```

Strategy: read form the file, skip ahead 4 lines, grab the reads and writes
=#
const _IO_DROP_LINES = 4

_parseline(ln) = tryparse(Int, last(split(ln)))

function measure(D::DiskIO, process)
    pid = getpid(process)
    bytesio = pidsafeopen("/proc/$pid/io", pid) do f
        iterator = drop(eachline(f), _IO_DROP_LINES)

        # First item from the iterator is the line for number of bytes read
        # TODO: Test for "nothing" to make the compiler happy.
        (line, s) = iterate(iterator)
        bytes_read = _parseline(line)

        # Second item is the bytes written
        (line, _) =  iterate(iterator, s)
        bytes_written = _parseline(line)

        return (read = bytes_read, write = bytes_written)
    end
    return bytesio
end
