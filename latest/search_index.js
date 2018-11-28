var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "MemSnoop",
    "title": "MemSnoop",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#MemSnoop-1",
    "page": "MemSnoop",
    "title": "MemSnoop",
    "category": "section",
    "text": "Idle page tracking for memory analysis of running applications."
},

{
    "location": "index.html#Security-Warning-1",
    "page": "MemSnoop",
    "title": "Security Warning",
    "category": "section",
    "text": "This package requires running julia as root because it needs access to several protected kernel files. To minimize your risk, this package\'s only dependency is the Serialization standard library. However, use this package at your own risk."
},

{
    "location": "index.html#MemSnoop.trace",
    "page": "MemSnoop",
    "title": "MemSnoop.trace",
    "category": "function",
    "text": "trace(pid; [sampletime], [iter], [filter], [callback]) -> Vector{Sample}\n\nRecord the full trace of pages accessed by an application with pid. Function will gracefully exit and return Vector{Sample} if process pid no longer exists.\n\nThe general flow of this function is as follows:\n\nSleep for sampletime.\nPause pid.\nGet the VMAs for pid, applying filter.\nRead all of the active pages.\nMark all pages as idle.\nCall callback\nResume `pid.\nRepeat for each element of iter.\n\nKeyword Arguments\n\nsampletime : Seconds between reading and reseting the idle page flags to determine page   activity. Default: 2\niter : Iterator to control the number of samples to take. Default behavior is to keep   sampling until monitored process terminates. Default: Run until program terminates.\nfilter : Filter to apply to process VMAs to reduce total amount of memory tracked.\ncallback : Optional callback for printing out status information (such as number    of iterations).\n\n\n\n\n\n"
},

{
    "location": "index.html#Generating-a-Trace-1",
    "page": "MemSnoop",
    "title": "Generating a Trace",
    "category": "section",
    "text": "Tracking a process is easy, simply call traceMemSnoop.traceThe trace function returns a Vector{Sample}. Each  Sample contains The VMAs assigned to the process for that sample interval.\nThe virtual page numbers of pages that were active during that sample interval.    Internally, these are stored as a SortedRangeVector for compression."
},

{
    "location": "index.html#Performing-Analysis-1",
    "page": "MemSnoop",
    "title": "Performing Analysis",
    "category": "section",
    "text": "Because of the dependency restriction, only basic functionality is provided in the MemSnoop package itself. For more detailed analyses that can be performed after a trace is generated, use the package SnoopAnalyzer.  Eventually, this package will also be documented here."
},

{
    "location": "docstring_index.html#",
    "page": "Docstring Index",
    "title": "Docstring Index",
    "category": "page",
    "text": ""
},

{
    "location": "docstring_index.html#Docstring-Index-1",
    "page": "Docstring Index",
    "title": "Docstring Index",
    "category": "section",
    "text": "Modules = [MemSnoop]"
},

{
    "location": "trace.html#",
    "page": "Traces",
    "title": "Traces",
    "category": "page",
    "text": ""
},

{
    "location": "trace.html#MemSnoop.Sample",
    "page": "Traces",
    "title": "MemSnoop.Sample",
    "category": "type",
    "text": "Simple container containing the list of VMAs analyzed for a sample as well as the individual pages accessed.\n\nFields\n\nvmas :: Vector{VMA} - The VMAs analyzed during this sample.\npages :: SortedRangeVector{UInt64} - The pages that were active during this sample. Pages are   encoded by virtual page number. To get an address, multiply the page number by the   pagesize (generally 4096).\n\nMethods\n\nvmas - VMAs of Sample.\npages - Active pages from Sample or Vector{Sample}.\nwss - Working set size of Sample.\nunion - Merge two Samples together.\nisactive - Check if a page was active in Sample.\nbitmap - Construct a bitmap of active pages for a Vector{Sample}.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.bitmap-Tuple{Array{Sample,1},VMA}",
    "page": "Traces",
    "title": "MemSnoop.bitmap",
    "category": "method",
    "text": "bitmap(trace::Vector{Sample}, vma::VMA) -> Array{Bool, 2}\n\nReturn a bitmap B of active pages in trace with virtual addresses from vma.  B[i,j] == true if the ith address in vma in trace[j] is active.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.pages-Tuple{Array{Sample,1}}",
    "page": "Traces",
    "title": "MemSnoop.pages",
    "category": "method",
    "text": "pages(trace::Vector{Sample}) -> Vector{UInt64}\n\nReturn a sorted vector of all pages in trace that were marked as \"active\" at least once. Pages are encoded by virtual page number.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.pages-Tuple{Sample}",
    "page": "Traces",
    "title": "MemSnoop.pages",
    "category": "method",
    "text": "pages(sample::Sample) -> Set{UInt64}\n\nReturn a set of all active pages in sample.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.trace-Tuple{Any}",
    "page": "Traces",
    "title": "MemSnoop.trace",
    "category": "method",
    "text": "trace(pid; [sampletime], [iter], [filter], [callback]) -> Vector{Sample}\n\nRecord the full trace of pages accessed by an application with pid. Function will gracefully exit and return Vector{Sample} if process pid no longer exists.\n\nThe general flow of this function is as follows:\n\nSleep for sampletime.\nPause pid.\nGet the VMAs for pid, applying filter.\nRead all of the active pages.\nMark all pages as idle.\nCall callback\nResume `pid.\nRepeat for each element of iter.\n\nKeyword Arguments\n\nsampletime : Seconds between reading and reseting the idle page flags to determine page   activity. Default: 2\niter : Iterator to control the number of samples to take. Default behavior is to keep   sampling until monitored process terminates. Default: Run until program terminates.\nfilter : Filter to apply to process VMAs to reduce total amount of memory tracked.\ncallback : Optional callback for printing out status information (such as number    of iterations).\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.vmas-Tuple{Array{Sample,1}}",
    "page": "Traces",
    "title": "MemSnoop.vmas",
    "category": "method",
    "text": "vmas(trace::Vector{Sample}) -> Vector{VMA}\n\nReturn the largest sorted collection V of VMAs with the property that for any sample S in trace and for any VMA s in S, s subset v for some v in V and s cap u = emptyset for all u in V setminus v.o\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.isactive-Tuple{Sample,Any}",
    "page": "Traces",
    "title": "MemSnoop.isactive",
    "category": "method",
    "text": "isactive(sample::Sample, page) -> Bool\n\nReturn true if page was active in sample.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.wss-Tuple{Sample}",
    "page": "Traces",
    "title": "MemSnoop.wss",
    "category": "method",
    "text": "wss(S::Sample) -> Int\n\nReturn the number of active pages for S.\n\n\n\n\n\n"
},

{
    "location": "trace.html#Traces-1",
    "page": "Traces",
    "title": "Traces",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"trace.jl\"]"
},

{
    "location": "process.html#",
    "page": "Process",
    "title": "Process",
    "category": "page",
    "text": ""
},

{
    "location": "process.html#MemSnoop.Process",
    "page": "Process",
    "title": "MemSnoop.Process",
    "category": "type",
    "text": "Struct container a pid as well as auxiliary data structure to make the snooping process more efficient.\n\nFields\n\npid::Int64 - The pid of the process.\nvmas::Vector{VMA} - Buffer for storing the VMAs assigned to this process.\nbuffer::Vector{UInt64} - Auxiliary array used as a buffer for the idle page map.\n\nConstructor\n\nProcess(pid) -> Process\n\nConstruct a Process with the given pid.\n\nMethods\n\ninitbuffer!\ngetvmas!\nwalkpagemap\nmarkidle\nreadidle\n\n\n\n\n\n"
},

{
    "location": "process.html#MemSnoop.initbuffer!-Tuple{MemSnoop.AbstractProcess}",
    "page": "Process",
    "title": "MemSnoop.initbuffer!",
    "category": "method",
    "text": "initbuffer!(p::AbstractProcess)\n\nRead once from page_idle/bitmap to get the size of the bitmap. Set the bitmap in p to this size to avoid reallocation every time the bitmap is read.\n\n\n\n\n\n"
},

{
    "location": "process.html#MemSnoop.markidle-Tuple{MemSnoop.AbstractProcess}",
    "page": "Process",
    "title": "MemSnoop.markidle",
    "category": "method",
    "text": "markidle(process::AbstractProcess)\n\nMark all of the memory pages assigned to process as idle.\n\n\n\n\n\n"
},

{
    "location": "process.html#MemSnoop.readidle-Tuple{MemSnoop.AbstractProcess}",
    "page": "Process",
    "title": "MemSnoop.readidle",
    "category": "method",
    "text": "readidle(process::AbstractProcess) -> SortedRangeVector{UInt}\n\nReturn the active pages of process.\n\n\n\n\n\n"
},

{
    "location": "process.html#MemSnoop.walkpagemap-Tuple{Function,Any,Any}",
    "page": "Process",
    "title": "MemSnoop.walkpagemap",
    "category": "method",
    "text": "walkpagemap(f::Function, pid, vmas; [buffer::Vector{UInt64}])\n\nFor each VMA in iterator vmas, store the contents of /proc/pid/pagemap into buffer for this VMA and call f(buffer).\n\nNote that it is possible for buffer to be empty.\n\n\n\n\n\n"
},

{
    "location": "process.html#Process-1",
    "page": "Process",
    "title": "Process",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"process.jl\"]"
},

{
    "location": "vma.html#",
    "page": "VMAs",
    "title": "VMAs",
    "category": "page",
    "text": ""
},

{
    "location": "vma.html#MemSnoop.VMA",
    "page": "VMAs",
    "title": "MemSnoop.VMA",
    "category": "type",
    "text": "Translated Virtual Memory Area (VMA) for a process.\n\nFields\n\nstart::UInt64 - The starting virtual page number for the VMA.\nstop::UInt64 - The last valid virtual page number for the VMA.\nremainder::String - The remainder of the entry in /proc/pid/maps.\n\nMethods\n\nlength, startaddress, stopaddress\n\n\n\n\n\n"
},

{
    "location": "vma.html#Base.compact-Tuple{Any}",
    "page": "VMAs",
    "title": "Base.compact",
    "category": "method",
    "text": "compact(vmas::Vector{VMA}) -> Vector{VMA}\n\nGiven an unsorted collection vmas, return the smallest collection V such that\n\nFor any u in vmas, u subset v for some v in V.\nAll elements of V are disjoint.\nV is sorted by starting address.\n\n\n\n\n\n"
},

{
    "location": "vma.html#Base.issubset-Tuple{VMA,VMA}",
    "page": "VMAs",
    "title": "Base.issubset",
    "category": "method",
    "text": "issubset(a::VMA, b::VMA) -> Bool\n\nReturn true if VMA region a is a subset of b.\n\n\n\n\n\n"
},

{
    "location": "vma.html#Base.length-Tuple{VMA}",
    "page": "VMAs",
    "title": "Base.length",
    "category": "method",
    "text": "length(vma::VMA) -> Int\n\nReturn the size of vma in number of pages.\n\n\n\n\n\n"
},

{
    "location": "vma.html#Base.union-Tuple{VMA,VMA}",
    "page": "VMAs",
    "title": "Base.union",
    "category": "method",
    "text": "union(a::VMA, b::VMA) -> VMA\n\nReturn a VMA that is the union of the regions covered by a and b. Assumes that a and b are overlapping.\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.executable-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.executable",
    "category": "method",
    "text": "Return true if vma is executable.\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.flagset-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.flagset",
    "category": "method",
    "text": "Return true if vma is either readable, writeable, or executable\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.getvmas!",
    "page": "VMAs",
    "title": "MemSnoop.getvmas!",
    "category": "function",
    "text": "getvmas!(buffer::Vector{VMA}, pid, [filter])\n\nFill buffer with the Virtual Memory Areas associated with the process with pid. Can optinally supply a filter. VMAs in buffer will be sorted by virtual address.\n\nFilter\n\nThe filter must be of the form\n\nf(vma::VMA) -> Bool\n\nwhere vma is the parsed VMA region from a line of the process\'s maps file.\n\nFor example, if an entry in the maps file is\n\n0088f000-010fe000 rw-p 00000000 00:00 0\n\nthen vma = VMA(0x0088f000,0x010fe000, rw-p 00000000 00:00 0)\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.heap-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.heap",
    "category": "method",
    "text": "Return true if vma is for the heap.\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.longerthan-Tuple{Any,Integer}",
    "page": "VMAs",
    "title": "MemSnoop.longerthan",
    "category": "method",
    "text": "longerthan(x, n) -> Bool\n\nReturn true if length(x) > n\n\nlongerthan(n) -> Function\n\nReturn a function x -> longerthan(x, n)\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.overlapping-Tuple{VMA,VMA}",
    "page": "VMAs",
    "title": "MemSnoop.overlapping",
    "category": "method",
    "text": "overlapping(a::VMA, b::VMA) -> Bool\n\nReturn true if VMA regions a and b overlap.\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.readable-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.readable",
    "category": "method",
    "text": "Return true if vma is readable.\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.startaddress-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.startaddress",
    "category": "method",
    "text": "startaddress(vma::VMA) -> UInt\n\nReturn the first virtual addresses assigned to vma.\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.stopaddress-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.stopaddress",
    "category": "method",
    "text": "stopaddres(vma::VMA) -> UInt\n\nReturn the last virtual addresses assigned to vma.\n\n\n\n\n\n"
},

{
    "location": "vma.html#MemSnoop.writable-Tuple{VMA}",
    "page": "VMAs",
    "title": "MemSnoop.writable",
    "category": "method",
    "text": "Return true if vma is writable.\n\n\n\n\n\n"
},

{
    "location": "vma.html#VMAs-1",
    "page": "VMAs",
    "title": "VMAs",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"vma.jl\"]"
},

{
    "location": "rangevector.html#",
    "page": "Sorted Range Vectors",
    "title": "Sorted Range Vectors",
    "category": "page",
    "text": ""
},

{
    "location": "rangevector.html#MemSnoop.SortedRangeVector",
    "page": "Sorted Range Vectors",
    "title": "MemSnoop.SortedRangeVector",
    "category": "type",
    "text": "Compact representation of data of type T that is both sorted and usually occurs in contiguous ranges. For example, since groups of virtual memory pages are usually accessed together, a SortedRangeVector can encode those more compactly than a normal vector.\n\nFields\n\nranges :: Vector{UnitRange{T} - The elements of the SortedRangeVector, compacted into   contiguous ranges.\n\nConstructor\n\nSortedRangeVector{T}() -> SortedRangeVector{T}\n\nConstruct a empty SortedRangeVector with element type T.\n\nMethods\n\nsumall\nlastelement\npush!\nin\nunion\n\n\n\n\n\n"
},

{
    "location": "rangevector.html#MemSnoop.lastelement-Tuple{SortedRangeVector}",
    "page": "Sorted Range Vectors",
    "title": "MemSnoop.lastelement",
    "category": "method",
    "text": "lastelement(V::SortedRangeVector{T}) -> T\n\nReturn the last element of the last range of V.\n\n\n\n\n\n"
},

{
    "location": "rangevector.html#MemSnoop.sumall-Union{Tuple{SortedRangeVector{T}}, Tuple{T}} where T",
    "page": "Sorted Range Vectors",
    "title": "MemSnoop.sumall",
    "category": "method",
    "text": "sumall(V::SortedRangeVector)\n\nReturn the sum of lengths of each element of V.\n\n\n\n\n\n"
},

{
    "location": "rangevector.html#Base.in-Tuple{Any,SortedRangeVector}",
    "page": "Sorted Range Vectors",
    "title": "Base.in",
    "category": "method",
    "text": "in(x, V::SortedRangeVector) -> Bool\n\nPerform an efficient search in V for x.\n\n\n\n\n\n"
},

{
    "location": "rangevector.html#Base.push!-Union{Tuple{T}, Tuple{SortedRangeVector{T},T}} where T",
    "page": "Sorted Range Vectors",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(V::SortedRangeVector{T}, x::T) where {T}\n\nAdd x to the end of V, merging x into the final range if appropriate.\n\npush!(V::SortedRangeVector{T}, x::UnitRange{T}) where {T}\n\nMerge x with the final range in V if they overlap. Otherwise, append x to the end of V.\n\nNOTE: Assumes that first(x) >= first(last(V)) \n\n\n\n\n\n"
},

{
    "location": "rangevector.html#Base.union-Union{Tuple{T}, Tuple{SortedRangeVector{T},SortedRangeVector{T}}} where T",
    "page": "Sorted Range Vectors",
    "title": "Base.union",
    "category": "method",
    "text": "union(A::SortedRangeVector, B::SortedRangeVector)\n\nEfficiently union A and B together.\n\n\n\n\n\n"
},

{
    "location": "rangevector.html#Sorted-Range-Vectors-1",
    "page": "Sorted Range Vectors",
    "title": "Sorted Range Vectors",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"rangevector.jl\"]"
},

{
    "location": "utils.html#",
    "page": "Utilities",
    "title": "Utilities",
    "category": "page",
    "text": ""
},

{
    "location": "utils.html#MemSnoop.Forever",
    "page": "Utilities",
    "title": "MemSnoop.Forever",
    "category": "type",
    "text": "In iterator that returns an infinite amount of nothing.\n\n\n\n\n\n"
},

{
    "location": "utils.html#MemSnoop.PIDException",
    "page": "Utilities",
    "title": "MemSnoop.PIDException",
    "category": "type",
    "text": "Exception indicating that process with pid no longer exists.\n\n\n\n\n\n"
},

{
    "location": "utils.html#MemSnoop.inmemory-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.inmemory",
    "category": "method",
    "text": "inmemory(x::UInt) -> Bool\n\nReturn true if x (interpreted as an entry in Linux /pagemap) if located in memory.\n\n\n\n\n\n"
},

{
    "location": "utils.html#MemSnoop.isactive-Tuple{Integer,Array{UInt64,1}}",
    "page": "Utilities",
    "title": "MemSnoop.isactive",
    "category": "method",
    "text": "isactive(x::Integer, buffer::Vector{UInt64}) -> Bool\n\nReturn true if bit x of buffer is set, intrerpreting buffer as a contiguous chunk  of memory.\n\n\n\n\n\n"
},

{
    "location": "utils.html#MemSnoop.isbitset-Tuple{Integer,Any}",
    "page": "Utilities",
    "title": "MemSnoop.isbitset",
    "category": "method",
    "text": "isbitset(x::Integer, b::Integer) -> Bool\n\nReturn true if bit b of x is 1.\n\n\n\n\n\n"
},

{
    "location": "utils.html#MemSnoop.pause-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.pause",
    "category": "method",
    "text": "pause(pid)\n\nPause process with pid. If process does not exist, throw a PIDException.\n\n\n\n\n\n"
},

{
    "location": "utils.html#MemSnoop.pfnmask-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.pfnmask",
    "category": "method",
    "text": "pfnmask(x::UInt) -> UInt\n\nReturn the lower 55 bits of x. When applied to a /proc/pid/pagemap entry, returns the physical page number (pfn) of that entry.\n\n\n\n\n\n"
},

{
    "location": "utils.html#MemSnoop.resume-Tuple{Any}",
    "page": "Utilities",
    "title": "MemSnoop.resume",
    "category": "method",
    "text": "resume(pid)\n\nResume process with pid. If process does not exist, throw a PIDException\n\n\n\n\n\n"
},

{
    "location": "utils.html#Utilities-1",
    "page": "Utilities",
    "title": "Utilities",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"util.jl\"]"
},

{
    "location": "hugepages.html#",
    "page": "Transparent Hugepages",
    "title": "Transparent Hugepages",
    "category": "page",
    "text": ""
},

{
    "location": "hugepages.html#MemSnoop.check_hugepages-Tuple{}",
    "page": "Transparent Hugepages",
    "title": "MemSnoop.check_hugepages",
    "category": "method",
    "text": "check_hugepages() -> Bool\n\nReturn true if Transparent Huge Pages are disabled. If THP are enabled, also print a warning.\n\n\n\n\n\n"
},

{
    "location": "hugepages.html#MemSnoop.enable_hugepages-Union{Tuple{Type{T}}, Tuple{T}} where T<:MemSnoop.TransparentHugePage",
    "page": "Transparent Hugepages",
    "title": "MemSnoop.enable_hugepages",
    "category": "method",
    "text": "enable_hugepages(::Type{T}) where {T <: TransparentHugePage}\n\nSet the status of Transparent Huge Pages to T.\n\n\n\n\n\n"
},

{
    "location": "hugepages.html#Transparent-Hugepages-1",
    "page": "Transparent Hugepages",
    "title": "Transparent Hugepages",
    "category": "section",
    "text": "Modules = [MemSnoop]\nPages = [\"hugepages.jl\"]"
},

{
    "location": "proof-of-concept.html#",
    "page": "Proof of Concept",
    "title": "Proof of Concept",
    "category": "page",
    "text": ""
},

{
    "location": "proof-of-concept.html#Proof-of-Concept-1",
    "page": "Proof of Concept",
    "title": "Proof of Concept",
    "category": "section",
    "text": "To verify that captured traces are behaving as expected, two synthetic workloads were written in c++ with predictable memory access patterns. These test files can be found in deps/src/ and can be built either with the Makefile in deps/ or by using Julia\'s package building functionality with the following # Switch to PKG mode\njulia> ]\n\n# Build MemSnoop - automatically building test workloads.\npkg> build MemSnoop"
},

{
    "location": "proof-of-concept.html#Test-Workload-1:-single.cpp-1",
    "page": "Proof of Concept",
    "title": "Test Workload 1: single.cpp",
    "category": "section",
    "text": "This workload uses a single statically allocated array A of 2000000 doubles. First, the program enters a wait loop for about 4 seconds. Then, it repeatedly accesses all of A for 4 seconds before returning to an idle loop for another 8 seconds. The code for the main routine is shown below:const int ARRAY_SIZE = 2000000;\nstatic double A[ARRAY_SIZE];\n\nint main(int argc, char *argv[])\n{\n    // Display the address of the first element of \"A\"\n    std::cout << &A[0] << \"\\n\";\n\n    // Time for array accesses (seconds)\n    int runtime = 4;\n\n    // Spend time doing nothing\n    wait(runtime);\n\n    // Repeatedly access \"A\" for \"runtime\" seconds\n    std::cout << \"Populating `a`\\n\"; \n    access(A, runtime);\n    std::cout << std::accumulate(A, A + ARRAY_SIZE, 0.0) << \"\\n\";\n\n    // Do nothing for a bit longer\n    wait(2 * runtime);\n\n    return 0;\n}In terms of access patterns, we would expect to see a relatively minimal accesses to any  memory address for the first four seconds, followed by access to a 2000000 * 8 = 16 MB  region of memory while the program is accessing A, followed by a period of relative calm again. Below is a plot of the captured trace for this workload:(Image: )Let\'s unpack this a little. First, the x-axis of the figure represents sample number -   MemSnoop was set to sample over two second periods. The y-axis roughly represents the virtual memory address with lower addresses on top and higher addresses on the bottom. (yes, I know this is backwards and will fix it eventually :(  ). Yellow indicates that a page was accessed (i.e. not idle) while purple indicates and idle page.Thus, we can see that the above image matches our intuation as to what should happen under the test workload. A large chunk of memory where the array A lives is idle for the first sample period, active for the next three, and idle again for the last two. Furthermore, we can estimate the size of the working set during the active phase by eyeballing the height of the middle yellow blob (exact numbers can be obtained easily from the trace itself). The central yellow mass has a height of roughly 4000, indicating that about 4000 virtual pages were accessed. If each page is 4096 bytes, this works out to around 16 MB of total accessed data, which matches what we\'d expect for the size of A."
},

{
    "location": "proof-of-concept.html#Test-Workload-2:-double.cpp-1",
    "page": "Proof of Concept",
    "title": "Test Workload 2: double.cpp",
    "category": "section",
    "text": "For the second synthetic workload, two static arrays A and B, each with 2000000  doubles were used. The program is idle for 4 seconds, accesses A for 4 seconds, accesses B for 4 seconds, and the is idle for 4 more seconds. The relevant code is shown below.const int ARRAY_SIZE = 2000000;\nstatic double A[ARRAY_SIZE];\nstatic double B[ARRAY_SIZE];\n\nint main(int argc, char *argv[])\n{\n    // Display addresses of items in memory\n    std::cout << &A[0] << \"\\n\";\n    std::cout << &B[0] << \"\\n\";\n\n    // Time for population\n    int time = 4;\n\n    // Spend time doing nothing\n    wait(time); \n\n    // Spend time populating \"A\"\n    std::cout << \"Populating `A`\\n\"; \n    access(A, time);\n    std::cout << std::accumulate(A, A + ARRAY_SIZE, 0.0) << \"\\n\";\n\n    // Spend time populating \"B\"\n    std::cout << \"Populating `B`\\n\"; \n    access(B, time);\n    std::cout << std::accumulate(B, B + ARRAY_SIZE, 0.0) << \"\\n\";\n\n    // Do nothing for a bit longer\n    wait(time);\n\n    return 0;\n}Here, we\'d expect a memory trace to begin with a period of relative calm, followed by one large region of memory being accessed, and then another large region of memory begin  accessed. A plot of the trace is shown below:(Image: )Once again, the plot seems to match our intuition, lending support that this technique might actually be working."
},

{
    "location": "thoughts.html#",
    "page": "Thoughts",
    "title": "Thoughts",
    "category": "page",
    "text": ""
},

{
    "location": "thoughts.html#Thoughts-1",
    "page": "Thoughts",
    "title": "Thoughts",
    "category": "section",
    "text": "DISCLAIMER: This is me basically sketching some ideas I had so I can put them in a more coherent form later. This is not meant yet to be understandable by others. Proceed with  caution :DOriginally, I had thought that sampling at a smaller time interval would yield strictly better results, but I\'m not so sure anymore. Here is an outline of my though process so far.Definition: Let t mathbbN to mathbbR^+ be a time sequence if t_0  0  and t_i+1  t_i.Definition: Define a sample S asS_t_i =  k  textPage k was active between t_i-1 and t_i be the set of pages of active pages on the time interval (t_i-1 t_i where t is a time sequence. As a syntactical choice, let S(t 0) = emptyset.Definition Define a trace T = (S_t_0 S_t_1 ldots S_t_n) be an ordered collection of samples.What we would like to show is that if we have two time sequences t and t^prime where t_i+1 - t_i leq t^prime _j+1 - t^prime _j for all index pairs i and j, (in other words, time sequence t has a smaller time interval than t^prime, then t is somehow a better approximation of the ground truth of reuse distance. To do  this, we need to define what we mean by reuse distance in the sense of discrete samples.Let t_0 and t_1 denote the times between subsequent accesses to some page k.  Furthermore, suppose the time sequence t denoting our samples times is such that for some index i, t_i-1  t_0 leq t_i and t_i+1  t_1 leq t_i+2. That is, the  sampling periods look something like what we have below:(Image: )We have to be conservative and say that the reuse distance for page k at this time interval isd(t i+2 k) = left S_t_i cup S_t_i+1 cup S_t_i+2 setminus k rightNow, we assume that page k is not accessed during S_t_i+. One source of error comes from over counting unique accesses on either side of the samples containing the page of interest.If subsequent accesses to page k are recorded in S_t_i and S_t_j, then a bound on the error in the reuse distance calculation isE =  S_t_i cup S_t_j setminus k  =  S_t_i cup S_t_j  - 1(Side note for further clarification, this works if we think of an oracle sampling function t^* where S_t^* _i = 1 for all valid i. I.E., a perfect trace).This is not taking into acount sub-sampling-frame rehits. "
},

{
    "location": "thoughts.html#A-pathological-example-1",
    "page": "Thoughts",
    "title": "A pathological example",
    "category": "section",
    "text": "Consider the following pathological example:(Image: )Here, we have two sampling periods, with the exact sequence of page hits shown by the  vertical bars. The exact trace histogram is shown on the left, with the one generated by the approximation shown on the right. The dashed bar is the approximated histogram is all  subpage accesses are recorded."
},

{
    "location": "thoughts.html#Error-Terms-1",
    "page": "Thoughts",
    "title": "Error Terms",
    "category": "section",
    "text": "Let t_i and t_j be sample times for subsequent accesses to page k. If we use the pessimistic distance formula, than the error in the reuse distance is S_t_i cup S_t_j  - 1Let r_{t_i} be the number of repeated accesses in S_{t_i}. Then the error here isr_t_i (S_t_i - 1)"
},

{
    "location": "thoughts.html#Idea-1",
    "page": "Thoughts",
    "title": "Idea",
    "category": "section",
    "text": "We can actually generate a lower bound AND an upper bound for reuse distance via sampling."
},

]}
