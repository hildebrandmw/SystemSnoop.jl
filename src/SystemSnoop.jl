module SystemSnoop

using Dates, Requires

export trace, SnoopedProcess, Pausable, Unpausable

function __init__()
    @require PAPI="25707955-362c-5858-b477-b2b4559b2019" include("optional/papi.jl")
    @require PCM="7d644800-0fd4-5f4f-871b-eb28bd968194" include("optional/pcm.jl")
end

#####
##### File Includes
#####

include("base.jl"); using .SnoopBase

# Measurements
include("measurements/measurements.jl")

end # module
