struct AccessPlot end

label(vma::VMA) = "$(string(vma.start, base = 16)) - $(string(vma.stop, base = 16))"

function compact(f, data, m, n)
    # preallocate an output array
    dims = div.(size(data), (m,n))
    out = Array{Float32}(undef, dims...)

    # Iterate over columns and rows
    for j in 1:dims[2], i in 1:dims[1]
        v = view(data, (m*(i-1) + 1):(m*i), (n*(j-1) + 1):(n*j))
        # Average the value over this region
        out[i,j] = f(v)
    end
    return out
end

threshold(x, p) = sum(x) / length(x) < p
shorterthan(x, s) = size(x, 1) <= s

subsample(x, n) = x[1:n:length(x)]

@recipe function f(::Type{AccessPlot}, trace;
        ycompact = 100,
        xcompact = 10,
        compact_fn = mean,
        vma_filter = x -> true,
        data_filter = x -> true,
    )

    # Apply VMA filter
    vmas = filter(vma_filter, vmas(trace))

    index = 1
    data = map(vmas) do v
        println("Processing Index $index of $(length(vmas))")
        index += 1

        @time bitmap = bitmap(trace, v)
        compact(compact_fn, bitmap(trace, v), ycompact, xcompact)
    end

    data = [compact(compact_fn, bitmap(trace, v), ycompact, xcompact) for v in vmas]
    println("Data Collected")

    # Filter out data that is below the given threshold of occupancy
    inds = findall(!data_filter, data)
    if length(inds) > 0
        deleteat!(vmas, inds)
        deleteat!(data, inds)
    end

    println("Data Filtered")

    ## SETUP TICKS
    # Want to put ticks at VMA boundaries with the start and stop addresses of the VMAs.
    # Locate ticks at VMA boundaries
    datasizes = size.(data, 1)
    tick_locations = [0]
    for size in take(datasizes, length(datasizes) - 1)
        push!(tick_locations, last(tick_locations) + size)
    end
    tick_labels = label.(vmas)

    yticks := (tick_locations, tick_labels)

    # Concatenate all the data together
    println("Concatenating data")
    fulldata = vcat(data...)
    println("Data fused")

    legend := false
    @series begin
        seriestype := :heatmap
        fulldata
    end

    # Draw white lines denoting vma boundaries
    seriestype := :line
    linecolor := :white

    # Size to full width of the plot
    width = size(fulldata, 2)
    for location in drop(tick_locations, 1)
        @series begin
            x = [0, width]
            y = [location, location]
            x,y
        end
    end
end
