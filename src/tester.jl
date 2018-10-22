const DEPSDIR = joinpath(@__DIR__, "..", "deps")
const PIDLAUNCHER = joinpath(DEPSDIR, "pidlauncher.sh")

function launch(name::String)
    # Resolve the path to the test. 
    path = joinpath(DEPSDIR, name) 
    pipe = Pipe()
    setup = pipeline(`$PIDLAUNCHER $path`; stdout = pipe)
    process = run(setup; wait = false)

    # Parse the first thing returned and let this process do its thing with reckless abandon
    return parse(Int, readline(pipe))
end
