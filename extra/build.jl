function build(tests)
    # Build the tests
    builddir = joinpath(@__DIR__, "build")
    ispath(builddir) || mkdir(builddir)

    # Compile the tests
    for test in tests
        run(`c++ -std=c++1y -O2 src/$test.cpp -o build/$test`)
    end
    return builddir
end
