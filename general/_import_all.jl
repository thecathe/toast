module General

    include("labels.jl")
    export Label, Labels

    include("num.jl")
    export Num
        
    include("value_clock.jl")
    export ClockValue
    
    include("value_time.jl")
    export TimeValue
end