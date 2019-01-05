# Measure the bytes read and written by a process

"""
Record the `rchar`, `wchar`, `read_bytes`, and `write_bytes` fields of `/proc/pid/io`.

Each measurement returns a [`BytesIO`](@ref) object.

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
BytesIO(3089822, 139463, 0, 4096)
```
"""
struct ProcessIO <: AbstractMeasurement end

"""
Struct representing measurements for [`ProcessIO`](@ref)

Fields
------
* `rchar` - Characters Read.  The number of bytes which this task has caused to be read 
    from storage.  This is simply the sum of bytes which this process passed  to  read(2)  
    and  similar  system calls. It  includes  things such as terminal I/O and is unaffected 
    by whether or not actual physical disk I/O was required (the read might have been 
    satisfied from pagecache).

* `wchar` - Characters Written. The number of bytes which this task has caused, or shall 
    cause to be written to disk.  Similar caveats apply here as with rchar.

* `read_bytes` - Attempt to count the number of bytes which this process really did cause to 
    be fetched from the storage layer.  This is accurate for block-backed filesystems.

* `write_bytes` - Attempt to count the number of bytes which this process caused to be sent 
    to the storage layer.
"""
struct BytesIO
    rchar::Int64
    wchar::Int64
    readbytes::Int64
    writebytes::Int64
end

prepare(::ProcessIO, args...) = Vector{BytesIO}()

function _parseline(ln) 
    ind = findlast(isequal(' '), ln)
    return safeparse(Int, SubString(ln, ind))
end

function measure(D::ProcessIO, process)
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

        return BytesIO(rchar, wchar, readbytes, writebytes)
    end


    return bytesio
end
