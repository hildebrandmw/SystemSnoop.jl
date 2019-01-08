using Documenter, SystemSnoop

makedocs(
    modules = [SystemSnoop],
    format = :html,
    sitename = "SystemSnoop.jl",
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
            "measurements/processio.md",
            "measurements/smaps.md",
            "measurements/statm.md",
            "measurements/uptime.md",
        ],
        "utils.md",
        "hugepages.md",
        "proof-of-concept.md",
        "thoughts.md",
        "docstring_index.md",
    ]
)

deploydocs(
    repo = "github.com/hildebrandmw/SystemSnoop.jl.git",
    target = "build",
    julia = "1.1",
    deps = nothing,
    make = nothing,
)
