module SnoopTest

const DEPSDIR = joinpath(@__DIR__, "..", "deps")

#####
##### Janky hack to build test dependencies
#####
const TESTS = ("single", "double")

testpath(test) = joinpath(DEPSDIR, "build", test)

function build(tests = TESTS)
    srcdir = joinpath(DEPSDIR, "cpp")
    builddir = joinpath(DEPSDIR, "build")
    ispath(builddir) || mkdir(builddir)

    # Build the tests
    for test in tests 
        run(`c++ -std=c++1y -O0 $srcdir/$test.cpp -o $builddir/$test`)
    end
end

function pidlaunch(test) 
    @assert in(test, TESTS)
    return launch(testpath(test))
end

"""
    launch(command::String) -> Int, Process, Pipe

Launch `command` as a process using the hacky `pidlauncher.sh` script. Return a tuple of 
process `pid`, the script `Process` itself, and a `Pipe` to the stdout of the process.
"""
function launch(command::String)
    # Resolve the path to the test. 
    pipe = Pipe()
    setup = pipeline(`$command`; stdout = pipe)
    process = run(setup; wait = false)

    # Parse the first thing returned and let this process do its thing with reckless abandon
    pid = getpid(process)
    return pid, process, pipe
end

end
