const DEPSDIR = joinpath(@__DIR__, "..", "deps")
const PIDLAUNCHER = joinpath(DEPSDIR, "pidlauncher.sh")

function testlaunch(name::String)
    # Resolve the path to the test. 
    path = joinpath(DEPSDIR, name) 
    mapped_stdout = Pipe()
    pipe = pipeline(`$PIDLAUNCHER $path`; stdout = mapped_stdout)
    process = run(pipe; wait = false)

    return parse(Int, readline(mapped_stdout))
end
