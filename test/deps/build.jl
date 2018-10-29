# Add the name of tests to compile here.
tests = ("single",)

# Create the build directory
srcdir = joinpath(@__DIR__, "src")
builddir = joinpath(@__DIR__, "build")
ispath(builddir) || mkdir(builddir)

# Compile each of the tests
for test in tests
    run(`c++ -std=c++1y -O0 $srcdir/$test.cpp -o $builddir/$test`)
end
