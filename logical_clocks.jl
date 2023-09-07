module LogicalClocks

    import Base.show
    import Base.string
    import Base.convert

    import Base.iterate

    import Base.length
    import Base.getindex
    import Base.push!
    import Base.isempty
    
    # re-export
    using ..General
    export ClockValue


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

end