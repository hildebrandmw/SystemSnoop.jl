# Measure the bytes read and written by a process

"""
Record the `rchar`, `wchar`, `read_bytes`, and `write_bytes` fields of `/proc/pid/io`.

Each measurement returns a `NamedTuple` with names `rchar`, `wchar`, `readbytes`, and
`writebytes`.

Example read from `/proc/pid/io`:
```
rchar: 3089822
wchar: 139463
syscr: 159
syscw: 178
read_bytes: 0
write_bytes: 4096
cancelled_write_bytes: 0
```
becomes
```
(rchar = 3089822, wchar = 139463, readbytes = 0, writebytes = 4096)
```
"""
struct DiskIO <: AbstractMeasurement end

const BytesIO = NamedTuple{(:rchar, :wchar, :readbytes, :writebytes), NTuple{4, Int64}}
prepare(::DiskIO, args...) = Vector{BytesIO}()

function _parseline(ln) 
    ind = findlast(isequal(' '), ln)
    return safeparse(Int, SubString(ln, ind))
end

function measure(D::DiskIO, process)
    pid = getpid(process)
    bytesio = pidsafeopen("/proc/$pid/io", pid) do f
        iterator = eachline(f)

        # First item from the iterator is the line for number of bytes read
        # TODO: Test for "nothing" to make the compiler happy.
        (line, s) = iterate(iterator)
        rchar = _parseline(line)

        # Second item is the bytes written
        (line, s) =  iterate(iterator, s)
        wchar = _parseline(line)

        ## Skip the next two lines
        (line, s) = iterate(iterator, s) 
        (line, s) = iterate(iterator, s) 

        # Get readbytes and writebytes
        (line, s) = iterate(iterator, s) 
        readbytes = _parseline(line)

        (line, _) = iterate(iterator, s) 
        writebytes = _parseline(line)

        return (
            rchar = rchar,
            wchar = wchar,
            readbytes = readbytes,
            writebytes = writebytes,
        )
    end
    return bytesio
end
