var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "SystemSnoop",
    "title": "SystemSnoop",
    "category": "page",
    "text": ""
},

{
    "location": "#SystemSnoop-1",
    "page": "SystemSnoop",
    "title": "SystemSnoop",
    "category": "section",
    "text": "Idle page tracking for memory analysis of running applications."
},

{
    "location": "#Security-Warning-1",
    "page": "SystemSnoop",
    "title": "Security Warning",
    "category": "section",
    "text": "This package requires running julia as root because it needs access to several protected kernel files. To minimize your risk, I tried minimize the number of third party non-stdlib  dependencies. The only third party non-test dependency of this package is  PAPI, which I also developed. That package  depends on Binary Provider, but only for building. Use this package at your own risk."
},

{
    "location": "#Usage-1",
    "page": "SystemSnoop",
    "title": "Usage",
    "category": "section",
    "text": "The bread and buffer of this package is the trace function. This function takes  a SnoopedProcess and a NamedTuple of AbstractMeasurements. For example, suppose we wanted to measure some metrics about the current Julia process. We would then do something like this:julia> using SystemSnoop\n\n# Procide the command we would like to run\njulia> process = `top`\n\n# Get a list of measurements we want to take. In this example, for each measurement we \n# perform an initial timestamp, monitor disk io, read the assigned and resident memory, \n# and take a final measurement\njulia> measurements = (\n    initial = SystemSnoop.Timestamp(),\n    disk = SystemSnoop.DiskIO(),\n    memory = SystemSnoop.Statm(),\n    final = SystemSnoop.Timestamp(),\n)\n\n# Then, we perform a series of measurements.\njulia> data = trace(command, measurements; sampletime = 1, iter = 1:3);\n\n# The resulting `data` is a named tuple with the same names as `measurements`. The values\n# themselves are the corresponding measurements.\njulia> data.initial\n3-element Array{Dates.DateTime,1}:\n 2019-01-03T16:57:39.064\n 2019-01-03T16:57:40.067\n 2019-01-03T16:57:41.069\n\njulia> data.disk\n3-element Array{NamedTuple{(:rchar, :wchar, :readbytes, :writebytes),NTuple{4,Int64}},1}:\n (rchar = 1948, wchar = 0, readbytes = 0, writebytes = 0)\n (rchar = 1948, wchar = 0, readbytes = 0, writebytes = 0)\n (rchar = 1948, wchar = 0, readbytes = 0, writebytes = 0)\n\njulia> data.memory\n3-element Array{NamedTuple{(:size, :resident),Tuple{Int64,Int64}},1}:\n (size = 1544, resident = 191)\n (size = 1544, resident = 191)\n (size = 1544, resident = 191)\n\njulia> data.final\n3-element Array{Dates.DateTime,1}:\n 2019-01-03T16:57:39.065\n 2019-01-03T16:57:40.067\n 2019-01-03T16:57:41.069One of the most powerful measurement types is Idle Page Tracking, though this  measurement requires Julia to be run as sudo to work."
},

{
    "location": "trace/#",
    "page": "Traces",
    "title": "Traces",
    "category": "page",
    "text": ""
},

{
    "location": "trace/#SystemSnoop.Timestamp",
    "page": "Traces",
    "title": "SystemSnoop.Timestamp",
    "category": "type",
    "text": "Collect timestamps.\n\n\n\n\n\n"
},

{
    "location": "trace/#Traces-1",
    "page": "Traces",
    "title": "Traces",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"trace.jl\"]"
},

{
    "location": "process/#",
    "page": "Process",
    "title": "Process",
    "category": "page",
    "text": ""
},

{
    "location": "process/#SystemSnoop.SnoopedProcess",
    "page": "Process",
    "title": "SystemSnoop.SnoopedProcess",
    "category": "type",
    "text": "Struct container a pid as well as auxiliary data structure to make the snooping process more efficient. SnoopedProcesses come in two variants, Pausable and Unpausable.\n\nPausable processes will be paused before a set of measurements are taken by calling kill -STOP and resumed after afterwards by calling kill -CONT. Unpausable processes will not be touched.\n\nTo construct a Pausable process with pid, call\n\nps = SnoopedProcess{Pausable}(pid)\n\nTo construct an Unpausable process, call\n\nps = SnoopedProcess{Unpausable}(pid)\n\nFields\n\npid::Int64 - The pid of the process.\n\nMethods\n\ngetpid - Get the PID of this process.\nisrunning - Return true if process is running.\nprehook - Method to call before measurements.\nposthook - Method to call after measurements.\n\n\n\n\n\n"
},

{
    "location": "process/#SystemSnoop.posthook-Tuple{SnoopedProcess{Pausable}}",
    "page": "Process",
    "title": "SystemSnoop.posthook",
    "category": "method",
    "text": "posthook(P::AbstractProcess)\n\nIf P is a pausable process, unpause P.\n\n\n\n\n\n"
},

{
    "location": "process/#SystemSnoop.prehook-Tuple{SnoopedProcess{Pausable}}",
    "page": "Process",
    "title": "SystemSnoop.prehook",
    "category": "method",
    "text": "prehook(P::AbstractProcess)\n\nIf P is a pausable process, pause P.\n\n\n\n\n\n"
},

{
    "location": "process/#Process-1",
    "page": "Process",
    "title": "Process",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"process.jl\"]"
},

{
    "location": "measurements/idlepages/idlepages/#",
    "page": "Idle Page Tracking",
    "title": "Idle Page Tracking",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/idlepages/idlepages/#Idle-Page-Tracking-1",
    "page": "Idle Page Tracking",
    "title": "Idle Page Tracking",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"idlepages/idlepages.jl\"]"
},

{
    "location": "measurements/idlepages/sample/#",
    "page": "Sample",
    "title": "Sample",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/idlepages/sample/#Sample-1",
    "page": "Sample",
    "title": "Sample",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"idlepages/sample.jl\"]"
},

{
    "location": "measurements/idlepages/vma/#",
    "page": "VMAs",
    "title": "VMAs",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/idlepages/vma/#VMAs-1",
    "page": "VMAs",
    "title": "VMAs",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"idlepages/vma.jl\"]"
},

{
    "location": "measurements/idlepages/rangevector/#",
    "page": "Sorted Range Vectors",
    "title": "Sorted Range Vectors",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/idlepages/rangevector/#Sorted-Range-Vectors-1",
    "page": "Sorted Range Vectors",
    "title": "Sorted Range Vectors",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"idlepages/rangevector.jl\"]"
},

{
    "location": "measurements/idlepages/utils/#",
    "page": "Utility Functions",
    "title": "Utility Functions",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/idlepages/utils/#Utility-Functions-1",
    "page": "Utility Functions",
    "title": "Utility Functions",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"idlepages/util.jl\"]"
},

{
    "location": "measurements/diskio/#",
    "page": "Disk IO",
    "title": "Disk IO",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/diskio/#Disk-IO-1",
    "page": "Disk IO",
    "title": "Disk IO",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"diskio.jl\"]"
},

{
    "location": "measurements/processio/#",
    "page": "Process IO",
    "title": "Process IO",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/processio/#Process-IO-1",
    "page": "Process IO",
    "title": "Process IO",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"processio.jl\"]"
},

{
    "location": "measurements/smaps/#",
    "page": "Smaps",
    "title": "Smaps",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/smaps/#Smaps-1",
    "page": "Smaps",
    "title": "Smaps",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"smaps.jl\"]"
},

{
    "location": "measurements/statm/#",
    "page": "Statm",
    "title": "Statm",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/statm/#Statm-1",
    "page": "Statm",
    "title": "Statm",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"statm.jl\"]"
},

{
    "location": "measurements/uptime/#",
    "page": "Uptime",
    "title": "Uptime",
    "category": "page",
    "text": ""
},

{
    "location": "measurements/uptime/#Uptime-1",
    "page": "Uptime",
    "title": "Uptime",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"uptime.jl\"]"
},

{
    "location": "utils/#",
    "page": "Utilities",
    "title": "Utilities",
    "category": "page",
    "text": ""
},

{
    "location": "utils/#Utilities-1",
    "page": "Utilities",
    "title": "Utilities",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"src/util.jl\"]"
},

{
    "location": "hugepages/#",
    "page": "Transparent Hugepages",
    "title": "Transparent Hugepages",
    "category": "page",
    "text": ""
},

{
    "location": "hugepages/#Transparent-Hugepages-1",
    "page": "Transparent Hugepages",
    "title": "Transparent Hugepages",
    "category": "section",
    "text": "Modules = [SystemSnoop]\nPages = [\"hugepages.jl\"]"
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
    "text": "To verify that captured traces are behaving as expected, two synthetic workloads were written in c++ with predictable memory access patterns. These test files can be found in deps/src/ and can be built either with the Makefile in deps/ or by using Julia\'s package building functionality with the following # Switch to PKG mode\njulia> ]\n\n# Build SystemSnoop - automatically building test workloads.\npkg> build SystemSnoop"
},

{
    "location": "proof-of-concept/#Test-Workload-1:-single.cpp-1",
    "page": "Proof of Concept",
    "title": "Test Workload 1: single.cpp",
    "category": "section",
    "text": "This workload uses a single statically allocated array A of 2000000 doubles. First, the program enters a wait loop for about 4 seconds. Then, it repeatedly accesses all of A for 4 seconds before returning to an idle loop for another 8 seconds. The code for the main routine is shown below:const int ARRAY_SIZE = 2000000;\nstatic double A[ARRAY_SIZE];\n\nint main(int argc, char *argv[])\n{\n    // Display the address of the first element of \"A\"\n    std::cout << &A[0] << \"\\n\";\n\n    // Time for array accesses (seconds)\n    int runtime = 4;\n\n    // Spend time doing nothing\n    wait(runtime);\n\n    // Repeatedly access \"A\" for \"runtime\" seconds\n    std::cout << \"Populating `a`\\n\"; \n    access(A, runtime);\n    std::cout << std::accumulate(A, A + ARRAY_SIZE, 0.0) << \"\\n\";\n\n    // Do nothing for a bit longer\n    wait(2 * runtime);\n\n    return 0;\n}In terms of access patterns, we would expect to see a relatively minimal accesses to any  memory address for the first four seconds, followed by access to a 2000000 * 8 = 16 MB  region of memory while the program is accessing A, followed by a period of relative calm again. Below is a plot of the captured trace for this workload:(Image: )Let\'s unpack this a little. First, the x-axis of the figure represents sample number -   SystemSnoop was set to sample over two second periods. The y-axis roughly represents the virtual memory address with lower addresses on top and higher addresses on the bottom. (yes, I know this is backwards and will fix it eventually :(  ). Yellow indicates that a page was accessed (i.e. not idle) while purple indicates and idle page.Thus, we can see that the above image matches our intuation as to what should happen under the test workload. A large chunk of memory where the array A lives is idle for the first sample period, active for the next three, and idle again for the last two. Furthermore, we can estimate the size of the working set during the active phase by eyeballing the height of the middle yellow blob (exact numbers can be obtained easily from the trace itself). The central yellow mass has a height of roughly 4000, indicating that about 4000 virtual pages were accessed. If each page is 4096 bytes, this works out to around 16 MB of total accessed data, which matches what we\'d expect for the size of A."
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
    "text": "Modules = [SystemSnoop]"
},

]}
