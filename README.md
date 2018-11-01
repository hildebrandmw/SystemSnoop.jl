# MemSnoop

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://hildebrandmw.github.io/MemSnoop.jl/stable) | ![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg) [![Build Status](https://travis-ci.org/hildebrandmw/MemSnoop.jl.svg?branch=master)](https://travis-ci.org/hildebrandmw/MemSnoop.jl) [![codecov.io](http://codecov.io/github/hildebrandmw/MemSnoop.jl/coverage.svg?branch=master)](http://codecov.io/github/hildebrandmw/MemSnoop.jl?branch=master) |

Tool that uses [idle page tracking](https://www.kernel.org/doc/html/latest/admin-guide/mm/idle_page_tracking.html)
to give insight in to the memory useage of arbitrary programs at the page level of 
granularity. The main functions are

```julia
trace(pid; [sampletime], [iter], [filter]) -> Trace
```

Which generates a full trace of virtual pages that were accessed with `sampletime` level
granularity, and

```
track_distance(pid; [sampletime], [iter], [filter]) -> DistanceTracker
```

which can be used to estimate Working Set Size (WSS) and the Reuse Distance of pages 
accesses within a program.  Note that the information provided by `track_distances` can be 
obtained from `trace`, but that `track_distances` will generally consume less memory. 

Refer to the documentation for more information on the technique and these functions.
