function test(samples)
    measurements = (
        data = Timestamp(),
    )
    sampler = SmartSample(Second(1))

    trace = snoop(measurements) do snooper
        # Initialize
        for _ in 1:samples
            measure!(snooper)
            sleep(sampler)
        end
    end
    return trace
end

