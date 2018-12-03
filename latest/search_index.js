var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "MemSnoop",
    "title": "MemSnoop",
    "category": "page",
    "text": ""
},

{
    "location": "#MemSnoop-1",
    "page": "MemSnoop",
    "title": "MemSnoop",
    "category": "section",
    "text": "Idle page tracking for memory analysis of running applications."
},

{
    "location": "#Security-Warning-1",
    "page": "MemSnoop",
    "title": "Security Warning",
    "category": "section",
    "text": "This package requires running julia as root because it needs access to several protected kernel files. To minimize your risk, this package\'s only dependency is the Serialization standard library. However, use this package at your own risk."
},

{
    "location": "#MemSnoop.trace",
    "page": "MemSnoop",
    "title": "MemSnoop.trace",
    "category": "function",
    "text": "trace(process::AbstractProcess, measurements::Tuple; kw...) -> Tuple\n\nPerform a measurement trace on process. The measurements to be performed are specified by the measurements argument. Return a tuple T where T[i] is the data for measurements[i].\n\nThe general flow of this function is as follows:\n\nSleep for sampletime\nCall prehook on process\nPerform measurements\nCall callback\nCall posthook on process\nRepeat for each element of iter.\n\nMeasurements\n\nmeasuremts::Tuple : A tuple where each element is some AbstractMeasurement.   By default, the only measurement performed is IdlePageTracker.\n\nKeyword Arguments\n\nsampletime : Seconds between reading and reseting the idle page flags to determine page   activity. Default: 2\niter : Iterator to control the number of samples to take. Default behavior is to keep   sampling until monitored process terminates. Default: Run until program terminates.\ncallback : Optional callback for printing out status information (such as number    of iterations).\n\n\n\n\n\n"
},

{
    "location": "#Generating-a-Trace-1",
    "page": "MemSnoop",
    "title": "Generating a Trace",
    "category": "section",
    "text": "Tracking a process is easy, simply call traceMemSnoop.traceThe trace function returns a Vector{Sample}. Each  Sample contains The VMAs assigned to the process for that sample interval.\nThe virtual page numbers of pages that were active during that sample interval.    Internally, these are stored as a SortedRangeVector for compression."
},

{
    "location": "#Performing-Analysis-1",
    "page": "MemSnoop",
    "title": "Performing Analysis",
    "category": "section",
    "text": "Because of the dependency restriction, only basic functionality is provided in the MemSnoop package itself. For more detailed analyses that can be performed after a trace is generated, use the package SnoopAnalyzer.  Eventually, this package will also be documented here."
},

{
    "location": "docstring_index/#",
    "page": "Docstring Index",
    "title": "Docstring Index",
    "category": "page",
    "text": ""
},

{
    "location": "docstring_index/#Docstring-Index-1",
    "page": "Docstring Index",
    "title": "Docstring Index",
    "category": "section",
    "text": "Modules = [MemSnoop]"
},

{
    "location": "trace/#",
    "page": "Traces",
    "title": "Traces",
    "category": "page",
    "text": ""
},

{
    "location": "trace/#MemSnoop.trace",
    "page": "Traces",
    "title": "MemSnoop.trace",
    "category": "function",
    "text": "trace(process::AbstractProcess, measurements::Tuple; kw...) -> Tuple\n\nPerform a measurement trace on process. The measurements to be performed are specified by the measurements argument. Return a tuple T where T[i] is the data for measurements[i].\n\nThe general flow of this function is as follows:\n\nSleep for sampletime\nCall prehook on process\nPerform measurements\nCall callback\nCall posthook on process\nRepeat for each element of iter.\n\nMeasurements\n\nmeasuremts::Tuple : A tuple where each element is some AbstractMeasurement.   By default, the only measurement performed is IdlePageTracker.\n\nKeyword Arguments\n\nsampletime : Seconds between reading and reseting the idle page flags to determine page   activity. Default: 2\niter : Iterator to control the number of samples to take. Default behavior is to keep   sampling until monitored process terminates. Default: Run until program terminates.\ncallback : Optional callback for printing out status information (such as number    of iterations).\n\n\n\n\n\n"
},

{
    "location": "trace/#MemSnoop.AbstractMeasurement",
    "page": "Traces",
    "title": "MemSnoop.AbstractMeasurement",
    "category": "type",
    "text": "Abstract supertype for process measurements.\n\nRequired API\n\nprepare\nmeasure\n\nOptional API\n\ninitialize!\n\nConcrete Implementations\n\nTimestamp\nIdlePageTracker\n\n\n\n\n\n"
},

{
    "location": "trace/#MemSnoop.Timestamp",
    "page": "Traces",
    "title": "MemSnoop.Timestamp",
    "category": "type",
    "text": "Collect timestamps.\n\n\n\n\n\n"
},

{
    "location": "trace/#MemSnoop.initialize!-Tuple{MemSnoop.AbstractMeasurement,Vararg{Any,N} where N}",
    "page": "Traces",
    "title": "MemSnoop.initialize!",
    "category": "method",
    "text": "initialize!(M::AbstractMeasurement, process::AbstractProcess)\n\nPerform any initialization required for measurement M. This method is optional and defaults to a no-op.\n\n\n\n\n\n"
},

{
    "location": "trace/#MemSnoop.measure-Union{Tuple{T}, Tuple{T,Vararg{Any,N} where N}} where T<:MemSnoop.AbstractMeasurement",
    "page": "Traces",
    "title": "MemSnoop.measure",
    "category": "method",
    "text": "measure(M::AbstractMeasurement, process::AbstractProcess) -> T\n\nReturn data of type T.\n\n\n\n\n\n"
},

{
    "location": "trace/#MemSnoop.prepare-Union{Tuple{T}, Tuple{T}} where T<:MemSnoop.AbstractMeasurement",
    "page": "Traces",
    "title": "MemSnoop.prepare",
    "category": "method",
    "text": "prepare(M::AbstractMeasurement) -> Vector{T}\n\nReturn an empty vector to hold measurement data of type T for measurement M.\n\n\n\n\n\n"
},

{
    "location": "trace/#Traces-1",
    "page": "Traces",
    "title": "Traces",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"trace.jl\"]"
},

{
    "location": "process/#",
    "page": "Process",
    "title": "Process",
    "category": "page",
    "text": ""
},

{
    "location": "process/#MemSnoop.SnoopedProcess",
    "page": "Process",
    "title": "MemSnoop.SnoopedProcess",
    "category": "type",
    "text": "Struct container a pid as well as auxiliary data structure to make the snooping process more efficient.\n\nFields\n\npid::Int64 - The pid of the process.\n\nConstructor\n\nSnoopedProcess(pid) -> SnoopedProcess\n\nConstruct a Process with the given pid.\n\nMethods\n\ngetpid - Get the PID of this process.\nprehook - Method to call before measurements.\nposthook - Method to call after measurements.\n\n\n\n\n\n"
},

{
    "location": "process/#MemSnoop.posthook-Tuple{MemSnoop.SnoopedProcess{MemSnoop.Pausable}}",
    "page": "Process",
    "title": "MemSnoop.posthook",
    "category": "method",
    "text": "posthook(P::AbstractProcess)\n\nIf P is a pausable process, unpause P.\n\n\n\n\n\n"
},

{
    "location": "process/#MemSnoop.prehook-Tuple{MemSnoop.SnoopedProcess{MemSnoop.Pausable}}",
    "page": "Process",
    "title": "MemSnoop.prehook",
    "category": "method",
    "text": "prehook(P::AbstractProcess)\n\nIf P is a pausable process, pause P.\n\n\n\n\n\n"
},

{
    "location": "process/#Process-1",
    "page": "Process",
    "title": "Process",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"process.jl\"]"
},

{
    "location": "rangevector/#",
    "page": "Sorted Range Vectors",
    "title": "Sorted Range Vectors",
    "category": "page",
    "text": ""
},

{
    "location": "rangevector/#MemSnoop.SortedRangeVector",
    "page": "Sorted Range Vectors",
    "title": "MemSnoop.SortedRangeVector",
    "category": "type",
    "text": "Compact representation of data of type T that is both sorted and usually occurs in contiguous ranges. For example, since groups of virtual memory pages are usually accessed together, a SortedRangeVector can encode those more compactly than a normal vector.\n\nFields\n\nranges :: Vector{UnitRange{T} - The elements of the SortedRangeVector, compacted into   contiguous ranges.\n\nConstructor\n\nSortedRangeVector{T}() -> SortedRangeVector{T}\n\nConstruct a empty SortedRangeVector with element type T.\n\nMethods\n\nsumall\nlastelement\npush!\nin\nunion\n\n\n\n\n\n"
},

{
    "location": "rangevector/#MemSnoop.lastelement-Tuple{SortedRangeVector}",
    "page": "Sorted Range Vectors",
    "title": "MemSnoop.lastelement",
    "category": "method",
    "text": "lastelement(V::SortedRangeVector{T}) -> T\n\nReturn the last element of the last range of V.\n\n\n\n\n\n"
},

{
    "location": "rangevector/#MemSnoop.sumall-Union{Tuple{SortedRangeVector{T}}, Tuple{T}} where T",
    "page": "Sorted Range Vectors",
    "title": "MemSnoop.sumall",
    "category": "method",
    "text": "sumall(V::SortedRangeVector)\n\nReturn the sum of lengths of each element of V.\n\n\n\n\n\n"
},

{
    "location": "rangevector/#Base.in-Tuple{Any,SortedRangeVector}",
    "page": "Sorted Range Vectors",
    "title": "Base.in",
    "category": "method",
    "text": "in(x, V::SortedRangeVector) -> Bool\n\nPerfor an efficient search in V for x.\n\n\n\n\n\n"
},

{
    "location": "rangevector/#Base.push!-Union{Tuple{T}, Tuple{SortedRangeVector{T},T}} where T",
    "page": "Sorted Range Vectors",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(V::SortedRangeVector{T}, x::T) where {T}\n\nAdd x to the end of V, merging x into the final range if appropriate.\n\npush!(V::SortedRangeVector{T}, x::UnitRange{T}) where {T}\n\nMerge x with the final range in V if they overlap. Otherwise, append x to the end of V.\n\nNOTE: Assumes that first(x) >= first(last(V)) \n\n\n\n\n\n"
},

{
    "location": "rangevector/#Base.union-Union{Tuple{T}, Tuple{SortedRangeVector{T},SortedRangeVector{T}}} where T",
    "page": "Sorted Range Vectors",
    "title": "Base.union",
    "category": "method",
    "text": "union(A::SortedRangeVector, B::SortedRangeVector)\n\nEfficiently union A and B together.\n\n\n\n\n\n"
},

{
    "location": "rangevector/#Sorted-Range-Vectors-1",
    "page": "Sorted Range Vectors",
    "title": "Sorted Range Vectors",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"rangevector.jl\"]"
},

{
    "location": "idlepages/idlepages/#",
    "page": "Idle Page Tracking",
    "title": "Idle Page Tracking",
    "category": "page",
    "text": ""
},

{
    "location": "idlepages/idlepages/#MemSnoop.IdlePageTracker",
    "page": "Idle Page Tracking",
    "title": "MemSnoop.IdlePageTracker",
    "category": "type",
    "text": "Measurement type for performing Idle Page Tracking on a process. To filter process VMAs, construct as\n\n    IdlePageTracker(filter)\n\nwhere filter is a VMA filter function.\n\nImplementation Details\n\nfilter - The VMA filter to apply.\nvmas::Vector{VMA} - Buffer for storing VMAs.\nbuffer::Vector{UInt64} - Buffer to store the idle page bitmap.\n\n\n\n\n\n"
},

{
    "location": "idlepages/idlepages/#MemSnoop.initbuffer!-Tuple{MemSnoop.IdlePageTracker}",
    "page": "Idle Page Tracking",
    "title": "MemSnoop.initbuffer!",
    "category": "method",
    "text": "initbuffer!(I::IdlePageTracker)\n\nRead once from page_idle/bitmap to get the size of the bitmap. Set the bitmap in I to this size to avoid reallocation every time the bitmap is read.\n\n\n\n\n\n"
},

{
    "location": "idlepages/idlepages/#MemSnoop.markidle-Tuple{Any,Any}",
    "page": "Idle Page Tracking",
    "title": "MemSnoop.markidle",
    "category": "method",
    "text": "markidle(pid, vmas)\n\nMark all of the memory pages in the list of vmas for process with pid as idle.\n\n\n\n\n\n"
},

{
    "location": "idlepages/idlepages/#MemSnoop.readidle-Tuple{Any,Any,Any}",
    "page": "Idle Page Tracking",
    "title": "MemSnoop.readidle",
    "category": "method",
    "text": "readidle(pid, vmas, buffer) -> SortedRangeVector{UInt}\n\nReturn the active pages within vmas of process with pid. Use buffer as storage for the idle bitmap to avoid allocations\n\n\n\n\n\n"
},

{
    "location": "idlepages/idlepages/#MemSnoop.walkpagemap-Tuple{Function,Any,Any}",
    "page": "Idle Page Tracking",
    "title": "MemSnoop.walkpagemap",
    "category": "method",
    "text": "walkpagemap(f::Function, pid, vmas; [buffer::Vector{UInt64}])\n\nFor each VMA in iterator vmas, store the contents of /proc/pid/pagemap into buffer for this VMA and call f(buffer).\n\nNote that it is possible for buffer to be empty.\n\n\n\n\n\n"
},

{
    "location": "idlepages/idlepages/#Idle-Page-Tracking-1",
    "page": "Idle Page Tracking",
    "title": "Idle Page Tracking",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"idlepages/idlepages.jl\"]"
},

{
    "location": "idlepages/sample/#",
    "page": "Sample",
    "title": "Sample",
    "category": "page",
    "text": ""
},

{
    "location": "idlepages/sample/#MemSnoop.Sample",
    "page": "Sample",
    "title": "MemSnoop.Sample",
    "category": "type",
    "text": "Simple container containing the list of VMAs analyzed for a sample as well as the individual pages accessed.\n\nFields\n\nvmas :: Vector{VMA} - The VMAs analyzed during this sample.\npages :: SortedRangeVector{UInt64} - The pages that were active during this sample. Pages are   encoded by virtual page number. To get an address, multiply the page number by the   pagesize (generally 4096).\n\nMethods\n\nvmas - VMAs of Sample.\npages - Active pages from Sample or Vector{Sample}.\nwss - Working set size of Sample.\nunion - Merge two Samples together.\nisactive - Check if a page was active in Sample.\nbitmap - Construct a bitmap of active pages for a Vector{Sample}.\n\n\n\n\n\n"
},

{
    "location": "idlepages/sample/#MemSnoop.bitmap-Tuple{Array{Sample,1},VMA}",
    "page": "Sample",
    "title": "MemSnoop.bitmap",
    "category": "method",
    "text": "bitmap(trace::Vector{Sample}, vma::VMA) -> Array{Bool, 2}\n\nReturn a bitmap B of active pages in trace with virtual addresses from vma.  B[i,j] == true if the ith address in vma in trace[j] is active.\n\n\n\n\n\n"
},

{
    "location": "idlepages/sample/#MemSnoop.pages-Tuple{Array{Sample,1}}",
    "page": "Sample",
    "title": "MemSnoop.pages",
    "category": "method",
    "text": "pages(trace::Vector{Sample}) -> Vector{UInt64}\n\nReturn a sorted vector of all pages in trace that were marked as \"active\" at least once. Pages are encoded by virtual page number.\n\n\n\n\n\n"
},

{
    "location": "idlepages/sample/#MemSnoop.pages-Tuple{Sample}",
    "page": "Sample",
    "title": "MemSnoop.pages",
    "category": "method",
    "text": "pages(sample::Sample) -> Set{UInt64}\n\nReturn a set of all active pages in sample.\n\n\n\n\n\n"
},

{
    "location": "idlepages/sample/#MemSnoop.vmas-Tuple{Array{Sample,1}}",
    "page": "Sample",
    "title": "MemSnoop.vmas",
    "category": "method",
    "text": "vmas(trace::Vector{Sample}) -> Vector{VMA}\n\nReturn the largest sorted collection V of VMAs with the property that for any sample S in trace and for any VMA s in S, s subset v for some v in V and s cap u = emptyset for all u in V setminus v.o\n\n\n\n\n\n"
},

{
    "location": "idlepages/sample/#MemSnoop.isactive-Tuple{Sample,Any}",
    "page": "Sample",
    "title": "MemSnoop.isactive",
    "category": "method",
    "text": "isactive(sample::Sample, page) -> Bool\n\nReturn true if page was active in sample.\n\n\n\n\n\n"
},

{
    "location": "idlepages/sample/#MemSnoop.wss-Tuple{Sample}",
    "page": "Sample",
    "title": "MemSnoop.wss",
    "category": "method",
    "text": "wss(S::Sample) -> Int\n\nReturn the number of active pages for S.\n\n\n\n\n\n"
},

{
    "location": "idlepages/sample/#Sample-1",
    "page": "Sample",
    "title": "Sample",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"idlepages/sample.jl\"]"
},

{
    "location": "idlepages/vma/#",
    "page": "VMAs",
    "title": "VMAs",
    "category": "page",
    "text": ""
},

{
    "location": "idlepages/vma/#MemSnoop.VMA",
    "page": "VMAs",
    "title": "MemSnoop.VMA",
    "category": "type",
    "text": "Translated Virtual Memory Area (VMA) for a process.\n\nFields\n\nstart::UInt64 - The starting virtual page number for the VMA.\nstop::UInt64 - The last valid virtual page number for the VMA.\nremainder::String - The remainder of the entry in /proc/pid/maps.\n\nMethods\n\nlength, startaddress, stopaddress\n\nFilter Functions\n\nThere are a handful of builtin filter functions to help get rid of unwanted VMAs.\n\nheap\nreadable\nwritable\nexecutable\nflagset\nlongerthan\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#Base.compact-Tuple{Any}",
    "page": "VMAs",
    "title": "Base.compact",
    "category": "method",
    "text": "compact(vmas::Vector{VMA}) -> Vector{VMA}\n\nGiven an unsorted collection vmas, return the smallest collection V such that\n\nFor any u in vmas, u subset v for some v in V.\nAll elements of V are disjoint.\nV is sorted by starting address.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#Base.issubset-Tuple{VMA,VMA}",
    "page": "VMAs",
    "title": "Base.issubset",
    "category": "method",
    "text": "issubset(a::VMA, b::VMA) -> Bool\n\nReturn true if VMA region a is a subset of b.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#Base.length-Tuple{VMA}",
    "page": "VMAs",
    "title": "Base.length",
    "category": "method",
    "text": "length(vma::VMA) -> Int\n\nReturn the size of vma in number of pages.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#Base.union-Tuple{VMA,VMA}",
    "page": "VMAs",
    "title": "Base.union",
    "category": "method",
    "text": "union(a::VMA, b::VMA) -> VMA\n\nReturn a VMA that is the union of the regions covered by a and b. Assumes that a and b are overlapping.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.executable-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.executable",
    "category": "method",
    "text": "Return true if vma is executable.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.flagset-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.flagset",
    "category": "method",
    "text": "Return true if vma is either readable, writeable, or executable\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.getvmas!",
    "page": "VMAs",
    "title": "MemSnoop.getvmas!",
    "category": "function",
    "text": "getvmas!(buffer::Vector{VMA}, pid, [filter])\n\nFill buffer with the Virtual Memory Areas associated with the process with pid. Can optinally supply a filter. VMAs in buffer will be sorted by virtual address.\n\nFilter\n\nThe filter must be of the form\n\nf(vma::VMA) -> Bool\n\nwhere vma is the parsed VMA region from a line of the process\'s maps file.\n\nFor example, if an entry in the maps file is\n\n0088f000-010fe000 rw-p 00000000 00:00 0\n\nthen vma = VMA(0x0088f000,0x010fe000, rw-p 00000000 00:00 0)\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.heap-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.heap",
    "category": "method",
    "text": "Return true if vma is for the heap.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.longerthan-Tuple{Any,Integer}",
    "page": "VMAs",
    "title": "MemSnoop.longerthan",
    "category": "method",
    "text": "longerthan(x, n) -> Bool\n\nReturn true if length(x) > n\n\nlongerthan(n) -> Function\n\nReturn a function x -> longerthan(x, n)\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.overlapping-Tuple{VMA,VMA}",
    "page": "VMAs",
    "title": "MemSnoop.overlapping",
    "category": "method",
    "text": "overlapping(a::VMA, b::VMA) -> Bool\n\nReturn true if VMA regions a and b overlap.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.readable-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.readable",
    "category": "method",
    "text": "Return true if vma is readable.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.startaddress-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.startaddress",
    "category": "method",
    "text": "startaddress(vma::VMA) -> UInt\n\nReturn the first virtual addresses assigned to vma.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.stopaddress-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.stopaddress",
    "category": "method",
    "text": "stopaddres(vma::VMA) -> UInt\n\nReturn the last virtual addresses assigned to vma.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#MemSnoop.writable-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.writable",
    "category": "method",
    "text": "Return true if vma is writable.\n\n\n\n\n\n"
},

{
    "location": "idlepages/vma/#VMAs-1",
    "page": "VMAs",
    "title": "VMAs",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"idlepages/vma.jl\"]"
},

{
    "location": "utils/#",
    "page": "Utilities",
    "title": "Utilities",
    "category": "page",
    "text": ""
},

{
    "location": "utils/#MemSnoop.Forever",
    "page": "Utilities",
    "title": "MemSnoop.Forever",
    "category": "type",
    "text": "In iterator that returns an infinite amount of nothing.\n\n\n\n\n\n"
},

{
    "location": "utils/#MemSnoop.PIDException",
    "page": "Utilities",
    "title": "MemSnoop.PIDException",
    "category": "type",
    "text": "Exception indicating that process with pid no longer exists.\n\n\n\n\n\n"
},

{
    "location": "utils/#MemSnoop.inmemory-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.inmemory",
    "category": "method",
    "text": "inmemory(x::UInt) -> Bool\n\nReturn true if x (interpreted as an entry in Linux /pagemap) if located in memory.\n\n\n\n\n\n"
},

{
    "location": "utils/#MemSnoop.isactive-Tuple{Integer,Array{UInt64,1}}",
    "page": "Utilities",
    "title": "MemSnoop.isactive",
    "category": "method",
    "text": "isactive(x::Integer, buffer::Vector{UInt64}) -> Bool\n\nReturn true if bit x of buffer is set, intrerpreting buffer as a contiguous chunk  of memory.\n\n\n\n\n\n"
},

{
    "location": "utils/#MemSnoop.isbitset-Tuple{Integer,Any}",
    "page": "Utilities",
    "title": "MemSnoop.isbitset",
    "category": "method",
    "text": "isbitset(x::Integer, b::Integer) -> Bool\n\nReturn true if bit b of x is 1.\n\n\n\n\n\n"
},

{
    "location": "utils/#MemSnoop.pause-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.pause",
    "category": "method",
    "text": "pause(pid)\n\nPause process with pid. If process does not exist, throw a PIDException.\n\n\n\n\n\n"
},

{
    "location": "utils/#MemSnoop.pfnmask-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.pfnmask",
    "category": "method",
    "text": "pfnmask(x::UInt) -> UInt\n\nReturn the lower 55 bits of x. When applied to a /proc/pid/pagemap entry, returns the physical page number (pfn) of that entry.\n\n\n\n\n\n"
},

{
    "location": "utils/#MemSnoop.resume-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.resume",
    "category": "method",
    "text": "resume(pid)\n\nResume process with pid. If process does not exist, throw a PIDException\n\n\n\n\n\n"
},

{
    "location": "utils/#Utilities-1",
    "page": "Utilities",
    "title": "Utilities",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"util.jl\"]"
},

{
    "location": "hugepages/#",
    "page": "Transparent Hugepages",
    "title": "Transparent Hugepages",
    "category": "page",
    "text": ""
},

{
    "location": "hugepages/#MemSnoop.check_hugepages-Tuple{}",
    "page": "Transparent Hugepages",
    "title": "MemSnoop.check_hugepages",
    "category": "method",
    "text": "check_hugepages() -> Bool\n\nReturn true if Transparent Huge Pages are disabled. If THP are enabled, also print a warning.\n\n\n\n\n\n"
},

{
    "location": "hugepages/#MemSnoop.enable_hugepages-Union{Tuple{Type{T}}, Tuple{T}} where T<:MemSnoop.TransparentHugePage",
    "page": "Transparent Hugepages",
    "title": "MemSnoop.enable_hugepages",
    "category": "method",
    "text": "enable_hugepages(::Type{T}) where {T <: TransparentHugePage}\n\nSet the status of Transparent Huge Pages to T.\n\n\n\n\n\n"
},

{
    "location": "hugepages/#Transparent-Hugepages-1",
    "page": "Transparent Hugepages",
    "title": "Transparent Hugepages",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"hugepages.jl\"]"
},

{
    "location": "proof-of-concept/#",
    "page": "Proof of Concept",
    "title": "Proof of Concept",
    "category": "page",
    "text": ""
},

{
    "location": "proof-of-concept/#Proof-of-Concept-1",
    "page": "Proof of Concept",
    "title": "Proof of Concept",
    "category": "section",
    "text": "To verify that captured traces are behaving as expected, two synthetic workloads were written in c++ with predictable memory access patterns. These test files can be found in deps/src/ and can be built either with the Makefile in deps/ or by using Julia\'s package building functionality with the following # Switch to PKG mode\njulia> ]\n\n# Build MemSnoop - automatically building test workloads.\npkg> build MemSnoop"
},

{
    "location": "proof-of-concept/#Test-Workload-1:-single.cpp-1",
    "page": "Proof of Concept",
    "title": "Test Workload 1: single.cpp",
    "category": "section",
    "text": "This workload uses a single statically allocated array A of 2000000 doubles. First, the program enters a wait loop for about 4 seconds. Then, it repeatedly accesses all of A for 4 seconds before returning to an idle loop for another 8 seconds. The code for the main routine is shown below:const int ARRAY_SIZE = 2000000;\nstatic double A[ARRAY_SIZE];\n\nint main(int argc, char *argv[])\n{\n    // Display the address of the first element of \"A\"\n    std::cout << &A[0] << \"\\n\";\n\n    // Time for array accesses (seconds)\n    int runtime = 4;\n\n    // Spend time doing nothing\n    wait(runtime);\n\n    // Repeatedly access \"A\" for \"runtime\" seconds\n    std::cout << \"Populating `a`\\n\"; \n    access(A, runtime);\n    std::cout << std::accumulate(A, A + ARRAY_SIZE, 0.0) << \"\\n\";\n\n    // Do nothing for a bit longer\n    wait(2 * runtime);\n\n    return 0;\n}In terms of access patterns, we would expect to see a relatively minimal accesses to any  memory address for the first four seconds, followed by access to a 2000000 * 8 = 16 MB  region of memory while the program is accessing A, followed by a period of relative calm again. Below is a plot of the captured trace for this workload:(Image: )Let\'s unpack this a little. First, the x-axis of the figure represents sample number -   MemSnoop was set to sample over two second periods. The y-axis roughly represents the virtual memory address with lower addresses on top and higher addresses on the bottom. (yes, I know this is backwards and will fix it eventually :(  ). Yellow indicates that a page was accessed (i.e. not idle) while purple indicates and idle page.Thus, we can see that the above image matches our intuation as to what should happen under the test workload. A large chunk of memory where the array A lives is idle for the first sample period, active for the next three, and idle again for the last two. Furthermore, we can estimate the size of the working set during the active phase by eyeballing the height of the middle yellow blob (exact numbers can be obtained easily from the trace itself). The central yellow mass has a height of roughly 4000, indicating that about 4000 virtual pages were accessed. If each page is 4096 bytes, this works out to around 16 MB of total accessed data, which matches what we\'d expect for the size of A."
},

{
    "location": "proof-of-concept/#Test-Workload-2:-double.cpp-1",
    "page": "Proof of Concept",
    "title": "Test Workload 2: double.cpp",
    "category": "section",
    "text": "For the second synthetic workload, two static arrays A and B, each with 2000000  doubles were used. The program is idle for 4 seconds, accesses A for 4 seconds, accesses B for 4 seconds, and the is idle for 4 more seconds. The relevant code is shown below.const int ARRAY_SIZE = 2000000;\nstatic double A[ARRAY_SIZE];\nstatic double B[ARRAY_SIZE];\n\nint main(int argc, char *argv[])\n{\n    // Display addresses of items in memory\n    std::cout << &A[0] << \"\\n\";\n    std::cout << &B[0] << \"\\n\";\n\n    // Time for population\n    int time = 4;\n\n    // Spend time doing nothing\n    wait(time); \n\n    // Spend time populating \"A\"\n    std::cout << \"Populating `A`\\n\"; \n    access(A, time);\n    std::cout << std::accumulate(A, A + ARRAY_SIZE, 0.0) << \"\\n\";\n\n    // Spend time populating \"B\"\n    std::cout << \"Populating `B`\\n\"; \n    access(B, time);\n    std::cout << std::accumulate(B, B + ARRAY_SIZE, 0.0) << \"\\n\";\n\n    // Do nothing for a bit longer\n    wait(time);\n\n    return 0;\n}Here, we\'d expect a memory trace to begin with a period of relative calm, followed by one large region of memory being accessed, and then another large region of memory begin  accessed. A plot of the trace is shown below:(Image: )Once again, the plot seems to match our intuition, lending support that this technique might actually be working."
},

{
    "location": "thoughts/#",
    "page": "Thoughts",
    "title": "Thoughts",
    "category": "page",
    "text": ""
},

{
    "location": "thoughts/#Thoughts-1",
    "page": "Thoughts",
    "title": "Thoughts",
    "category": "section",
    "text": "DISCLAIMER: This is me basically sketching some ideas I had so I can put them in a more coherent form later. This is not meant yet to be understandable by others. Proceed with  caution :DOriginally, I had thought that sampling at a smaller time interval would yield strictly better results, but I\'m not so sure anymore. Here is an outline of my though process so far.Definition: Let t mathbbN to mathbbR^+ be a time sequence if t_0  0  and t_i+1  t_i.Definition: Define a sample S asS_t_i =  k  textPage k was active between t_i-1 and t_i be the set of pages of active pages on the time interval (t_i-1 t_i where t is a time sequence. As a syntactical choice, let S(t 0) = emptyset.Definition Define a trace T = (S_t_0 S_t_1 ldots S_t_n) be an ordered collection of samples.What we would like to show is that if we have two time sequences t and t^prime where t_i+1 - t_i leq t^prime _j+1 - t^prime _j for all index pairs i and j, (in other words, time sequence t has a smaller time interval than t^prime, then t is somehow a better approximation of the ground truth of reuse distance. To do  this, we need to define what we mean by reuse distance in the sense of discrete samples.Let t_0 and t_1 denote the times between subsequent accesses to some page k.  Furthermore, suppose the time sequence t denoting our samples times is such that for some index i, t_i-1  t_0 leq t_i and t_i+1  t_1 leq t_i+2. That is, the  sampling periods look something like what we have below:(Image: )We have to be conservative and say that the reuse distance for page k at this time interval isd(t i+2 k) = left S_t_i cup S_t_i+1 cup S_t_i+2 setminus k rightNow, we assume that page k is not accessed during S_t_i+. One source of error comes from over counting unique accesses on either side of the samples containing the page of interest.If subsequent accesses to page k are recorded in S_t_i and S_t_j, then a bound on the error in the reuse distance calculation isE =  S_t_i cup S_t_j setminus k  =  S_t_i cup S_t_j  - 1(Side note for further clarification, this works if we think of an oracle sampling function t^* where S_t^* _i = 1 for all valid i. I.E., a perfect trace).This is not taking into acount sub-sampling-frame rehits. "
},

{
    "location": "thoughts/#A-pathological-example-1",
    "page": "Thoughts",
    "title": "A pathological example",
    "category": "section",
    "text": "Consider the following pathological example:(Image: )Here, we have two sampling periods, with the exact sequence of page hits shown by the  vertical bars. The exact trace histogram is shown on the left, with the one generated by the approximation shown on the right. The dashed bar is the approximated histogram is all  subpage accesses are recorded."
},

{
    "location": "thoughts/#Error-Terms-1",
    "page": "Thoughts",
    "title": "Error Terms",
    "category": "section",
    "text": "Let t_i and t_j be sample times for subsequent accesses to page k. If we use the pessimistic distance formula, than the error in the reuse distance is S_t_i cup S_t_j  - 1Let r_{t_i} be the number of repeated accesses in S_{t_i}. Then the error here isr_t_i (S_t_i - 1)"
},

{
    "location": "thoughts/#Idea-1",
    "page": "Thoughts",
    "title": "Idea",
    "category": "section",
    "text": "We can actually generate a lower bound AND an upper bound for reuse distance via sampling."
},

]}
