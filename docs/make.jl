using Documenter, MemSnoop

makedocs(
    modules = [MemSnoop],
    format = :html,
    sitename = "MemSnoop.jl",
    html_prettyurls = get(ENV, "CI", nothing) == "true",
    pages = Any[
        "index.md", 
        "trace.md",
        "process.md",
        "Measurements" => [
            "Idle Page Tracking" => [
                "measurements/idlepages/idlepages.md",
                "measurements/idlepages/sample.md",
                "measurements/idlepages/vma.md",
                "measurements/idlepages/rangevector.md",
                "measurements/idlepages/utils.md",
            ],
            "measurements/diskio.md",
            "measurements/statm.md",
        ],
        "utils.md",
        "hugepages.md",
        "proof-of-concept.md",
        "thoughts.md",
        "docstring_index.md",
    ]
)

deploydocs(
    repo = "github.com/hildebrandmw/MemSnoop.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
