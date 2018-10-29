const DEPSDIR = joinpath(@__DIR__, "..", "deps")
const PIDLAUNCHER = joinpath(DEPSDIR, "pidlauncher.sh")

"""
    launch(command::String) -> Int, Process, Pipe

Launch `command` as a process using the hacky `pidlauncher.sh` script. Return a tuple of 
process `pid`, the script `Process` itself, and a `Pipe` to the stdout of the process.
"""
function launch(command::String)
    # Resolve the path to the test. 
    pipe = Pipe()
    setup = pipeline(`$PIDLAUNCHER $command`; stdout = pipe)
    process = run(setup; wait = false)

    # Parse the first thing returned and let this process do its thing with reckless abandon
    pid = parse(Int, readline(pipe)) 
    return pid, process, pipe
end
