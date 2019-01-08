# SystemSnoop

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-latest-img]][docs-latest-url] | [![][travis-img]][travis-url] ![][lifecycle-img] [![][codecov-img]][codecov-url] |

Tool that uses [idle page tracking](https://www.kernel.org/doc/html/latest/admin-guide/mm/idle_page_tracking.html)
to give insight in to the memory useage of arbitrary programs at the page level of 
granularity. The main function is

```julia
trace(pid, measurements; [sampletime], [iter], [filter]) -> Vector{Sample}
```

Which generates a full trace of virtual pages that were accessed with `sampletime` level
granularity.

Refer to the documentation for more information on the technique and these functions.

## Installation

### Basic Installation

From inside the Julia REPL, press `]` to enter `pkg` mode, then type the following:
```julia
# Install PAPI
pkg> add https://github.com/hildebrandmw/PAPI.jl

# Install SystemSnoop
pkg. add https://github.com/hildebrandmw/SystemSnoop.jl
```

### Development Installation

If you want to develop the code, you can either replace the `add` commands above with `dev`,
in which case Julia's package manager will download the repos into `~/.julia/dev`.

Alternatively, if you want to clone the git repos manually, you can run
```sh
git clone https://github.com/hildebrandmw/PAPI.jl PAPI
git clone https://github.com/hildebrandmw/SystemSnoop.jl SystemSnoop
```
Then start Julia and do
```julia
julia> ]

pkg> dev ./PAPI

pkg> dev ./SystemSnoop
```


[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://hildebrandmw.github.io/SystemSnoop.jl/latest

[lifecycle-img]: https://img.shields.io/badge/lifecycle-experimental-orange.svg

[travis-img]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl.svg?branch=master
[travis-url]: https://travis-ci.org/hildebrandmw/SystemSnoop.jl

[codecov-img]: http://codecov.io/github/hildebrandmw/SystemSnoop.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/hildebrandmw/SystemSnoop.jl?branch=master
