# Create the build folder if needed.
if !ispath(joinpath(@__DIR__, "build"))
    mkdir(joinpath(@__DIR__, "build"))
end

# Run the "make" command.
run(`make -C $(@__DIR__)`)
