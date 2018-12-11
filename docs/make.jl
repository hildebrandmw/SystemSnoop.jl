using Documenter, MemSnoop

makedocs(
    modules = [MemSnoop],
    format = :html,
    sitename = "MemSnoop.jl",
    html_prettyurls = get(ENV, "CI", nothing) == "true",
    pages = Any[
        "index.md", 
        "docstring_index.md",
        "trace.md",
        "process.md",
        "Analyses" => [
            "Idle Page Tracking" => [
                "idlepages/idlepages.md",
                "idlepages/sample.md",
                "idlepages/vma.md",
                "idlepages/rangevector.md",
                "idlepages/utils.md",
            ],
            "diskio/diskio.md",
        ],
        "utils.md",
        "hugepages.md",
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
