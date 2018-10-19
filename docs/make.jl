using Documenter, MemSnoop

makedocs(
    modules = [MemSnoop],
    format = :html,
    sitename = "MemSnoop.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/hildebrandmw/MemSnoop.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
