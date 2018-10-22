using Makie

function plot(trace)
    # Get all of the virtual pages seen in the trace.
    pages = allpages(trace)

    bitmap = [washit(sample, page) for sample in trace.samples, page in pages]

    return heatmap(bitmap)
end

function allpages(trace)
    pages = Set{Int}()
    for sample in trace.samples
        for vma in sample.vmas
            for hit in vma.hits
                push!(pages, hit)
            end
        end
    end
    return (sort ∘ collect)(pages)
end

function washit(sample, page)
    for vma in sample.vmas
        in(page, vma.hits) && return true
    end
    return false
end
