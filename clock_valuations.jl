module ClockValuations

    import Base.show
    import Base.string

    using ..General
    using ..LogicalClocks
    # import ..LogicalClocks.time_step!
    using ..ClockConstraints
    
    export Valuations, time_step!, value!, reset!, global_clock

    const global_clock = Label("𝒢")
    
    # valuations
    mutable struct Valuations
        clocks::Clocks
        system::Clock
        function Valuations(clocks,system=Clock(global_clock,0)) 
            @assert !(system.label in labels(clocks)) "Global-system clock '$(system.label)' cannot be in local clocks: $(string(clocks))"
            
            new(clocks,system)
        end
    end
    Base.show(v::Valuations, io::Core.IO = stdout) = print(io, string(v))
    Base.show(v::Valuations, verbose::Bool, io::Core.IO = stdout) = print(io, string(v,verbose))
    Base.string(v::Valuations, verbose::Bool = false) = string(join(Labels([string(v.system), Labels([string(c) for c in v.clocks])...]), ", "))

    # return value of valuation, using offset of global clock if necesary
    function value!(v::Valuations,l::Label)
        if l == v.system.label
            return (v.system.value, l, true)
        else
            return LogicalClocks.clock_value!(v.clocks,l,v.system.value)
        end
    end

    time_step!(v::Valuations, t::T) where {T<:Integer} = time_step!(v,TimeValue(t))
    function time_step!(v::Valuations,t::TimeValue)
        v.system.value += t.value
        time_pass!(v.clocks,t)
    end
    
    # resets clocks with labels to 0
    reset!(v::Valuations, l::Array{String}) = reset!(v,Labels(l))
    function reset!(v::Valuations, l::Labels) 
        @assert !(v.system.label in l) "Global-system clock '$(v.system.label)' cannot be reset to 0!"
        # for each label a in l
        # if a value already exists for a
        # then set a to 0
        # (use value! of clock to ensure that any new clocks are initialised to 0)
        foreach(a -> if (LogicalClocks.clock_value!(v.clocks,a) == (~,~,true))  getindex(v,findfirst(x -> x.label == l, v)).value = ClockValue(0) end, l)
    end

    # evaluate constraint against clocks


end