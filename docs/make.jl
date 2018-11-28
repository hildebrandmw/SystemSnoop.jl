using Documenter, MemSnoop

makedocs(
    modules = [MemSnoop],
    format = :html,
    sitename = "MemSnoop.jl",
    pages = Any[
        "index.md", 
        "Implementation" => Any[
            "docstring_index.md",
            "trace.md",
            "process.md",
            "vma.md",
            "rangevector.md",
            "utils.md",
            "hugepages.md",
        ],
        "proof-of-concept.md",
        "thoughts.md",
    ]
)

deploydocs(
    repo = "github.com/hildebrandmw/MemSnoop.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
