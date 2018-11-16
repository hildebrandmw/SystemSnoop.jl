# MemSnoop

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://hildebrandmw.github.io/MemSnoop.jl/latest) | ![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg) [![Build Status](https://travis-ci.org/hildebrandmw/MemSnoop.jl.svg?branch=master)](https://travis-ci.org/hildebrandmw/MemSnoop.jl) [![codecov.io](http://codecov.io/github/hildebrandmw/MemSnoop.jl/coverage.svg?branch=master)](http://codecov.io/github/hildebrandmw/MemSnoop.jl?branch=master) |

Tool that uses [idle page tracking](https://www.kernel.org/doc/html/latest/admin-guide/mm/idle_page_tracking.html)
to give insight in to the memory useage of arbitrary programs at the page level of 
granularity. The main function is

```julia
trace(pid; [sampletime], [iter], [filter]) -> Vector{Sample}
```

Which generates a full trace of virtual pages that were accessed with `sampletime` level
granularity.

Refer to the documentation for more information on the technique and these functions.
