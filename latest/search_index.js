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
    "text": "Idle page tracking for memory analysis."
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
    "location": "trace.html#",
    "page": "Full Traces",
    "title": "Full Traces",
    "category": "page",
    "text": ""
},

{
    "location": "trace.html#MemSnoop.trace",
    "page": "Full Traces",
    "title": "MemSnoop.trace",
    "category": "function",
    "text": "trace(pid; [sampletime], [iter], [filter]) -> Vector{Sample}\n\nRecord the full trace of pages accessed by an application with pid. Function will gracefully exit and return Vector{Sample} if process pid no longer exists.\n\nThe general flow of this function is as follows:\n\nSleep for sampletime.\nPause pid.\nGet the VMAs for pid, applying filter.\nRead all of the active pages.\nMark all pages as idle.\nResume `pid.\nRepeat for each element of iter.\n\nKeyword Arguments\n\nsampletime : Seconds between reading and reseting the idle page flags to determine page   activity. Default: 2\niter : Iterator to control the number of samples to take. Default behavior is to keep   sampling until monitored process terminates. Default: Run until program terminates.\nfilter : Filter to apply to process VMAs to reduce total amount of memory tracked.\n\n\n\n\n\n"
},

{
    "location": "trace.html#Full-Traces-1",
    "page": "Full Traces",
    "title": "Full Traces",
    "category": "section",
    "text": "MemSnoop has the ability to record the full trace of pages accessed by an application. This is performed using traceMemSnoop.trace"
},

{
    "location": "trace.html#MemSnoop.Sample",
    "page": "Full Traces",
    "title": "MemSnoop.Sample",
    "category": "type",
    "text": "Simple container containing the list of VMAs analyzed for a sample as well as the individual pages accessed.\n\nFields\n\nvmas :: Vector{VMA} - The VMAs analyzed during this sample.\npages :: RangeVector{UInt64} - The pages that were active during this sample. Pages are   encoded by virtual page number. To get an address, multiply the page number by the   pagesize (generally 4096).\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.isactive-Tuple{MemSnoop.Sample,Any}",
    "page": "Full Traces",
    "title": "MemSnoop.isactive",
    "category": "method",
    "text": "isactive(sample::Sample, page) -> Bool\n\nReturn true if page was active in sample.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.pages",
    "page": "Full Traces",
    "title": "MemSnoop.pages",
    "category": "function",
    "text": "pages(sample::Sample) -> Set{UInt64}\n\nReturn a set of all active pages in sample.\n\n\n\n\n\npages(trace::Vector{Sample}) -> Vector{UInt64}\n\nReturn a sorted vector of all pages in trace that were marked as \"active\" at least once. Pages are encoded by virtual page number.\n\n\n\n\n\n"
},

{
    "location": "trace.html#Implementation-Details-Sample-1",
    "page": "Full Traces",
    "title": "Implementation Details - Sample",
    "category": "section",
    "text": "MemSnoop.Sample\nMemSnoop.isactive(::MemSnoop.Sample, ::Any)\nMemSnoop.pages"
},

{
    "location": "trace.html#MemSnoop.RangeVector",
    "page": "Full Traces",
    "title": "MemSnoop.RangeVector",
    "category": "type",
    "text": "Compact representation of data of type T that is both sorted and usually occurs in contiguous ranges. For example, since groups of virtual memory pages are usually accessed together, a RangeVector can encode those more compactly than a normal vector.\n\nFields\n\nranges :: Vector{UnitRange{T} - The elements of the RangeVector, compacted into   contiguous ranges.\n\nConstructor\n\nRangeVector{T}() -> RangeVector{T}\n\nConstruct a empty RangeVector with element type T.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.lastelement",
    "page": "Full Traces",
    "title": "MemSnoop.lastelement",
    "category": "function",
    "text": "lastelement(R::RangeVector{T}) -> T\n\nReturn the last element of the last range of R.\n\n\n\n\n\n"
},

{
    "location": "trace.html#Base.push!-Union{Tuple{T}, Tuple{RangeVector{T},T}} where T",
    "page": "Full Traces",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(R::RangeVector{T}, x::T)\n\nAdd x to the end of R, merging x into the final range if appropriate.\n\n\n\n\n\n"
},

{
    "location": "trace.html#MemSnoop.insorted",
    "page": "Full Traces",
    "title": "MemSnoop.insorted",
    "category": "function",
    "text": "insorted(R::RangeVector, x) -> Bool\n\nPerform an efficient search of R for item x, assuming the ranges in R are sorted and non-overlapping.\n\n\n\n\n\n"
},

{
    "location": "trace.html#Implementation-Details-RangeVector-1",
    "page": "Full Traces",
    "title": "Implementation Details - RangeVector",
    "category": "section",
    "text": "Since pages are generally accessed sequentially, the record of active pages is encoded as a MemSnoop.RangeVector that compresses contiguous runs of accesses. Note that  there is an implicit assumption that the VMAs are ordered, which should be the case since  /prod/pid/maps orderes VMAs.MemSnoop.RangeVector\nMemSnoop.lastelement\npush!(::MemSnoop.RangeVector{T}, x::T) where T\nMemSnoop.insorted"
},

]}
