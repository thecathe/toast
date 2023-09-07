module LogicalClocks

    export Num
    const Num = T where {T<:Number}

    #
    # clock
    #
    include("logical_clocks/logical_clock.jl")
    using .LogicalClock
    export Clock
    
    include("logical_clocks/clock_resets.jl")
    using .ClockResets
    export λ

    #
    # valuations
    #
    include("logical_clocks/clock_valuations.jl")
    using .ClockValuations
    export Valuations, ValueOf!, ResetClocks!, TimeStep!
    
    #
    # clock constraints
    #
    include("logical_clocks/clock_constraints.jl")
    using .ClockConstraints
    export δ, δExpr, supported_constraints

end