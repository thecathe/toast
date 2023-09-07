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
    export Valuations


    export value!, reset!, time_step!, labels

    
    # Base.convert(::Type{UnitOfTime}, t::T) where {T<:Int} = UnitOfTime(t)

    # returns value of clock, instansiating to offset if not existing
    value!(c::Clocks,l::String,offset::T) where {T<:Number} = value!(c,Label(l),ClockValue(offset))
    function value!(c::Clocks, l::Label, offset::ClockValue = ClockValue(0))
        if l in labels(c)
            for x in c.children
                if x.label == l
                    return (ClockValue(x.value), l, true)
                end
            end
        else
            push!(c, Clock(l, offset))
            return (ClockValue(offset), l, false)
        end
    end

    # show value correctly
    Base.show(val::Tuple{ClockValue,Label,Bool},io::Core.IO = stdout) = print(io, string(val))
    Base.show(val::Tuple{ClockValue,Label,Bool}, verbose::Bool ,io::Core.IO = stdout) = print(io, string(val,verbose))
    Base.string(val::Tuple{ClockValue,Label,Bool}, verbose::Bool = true) = string(string(Clock(val[2],val[1])), val[3] && verbose ? "" : " *fresh*")

    # resets clocks with labels to 0
    reset!(c::Clocks, l::T) where {T<:Array{Any}} = reset!(c,Labels(l))
    reset!(c::Clocks, l::T) where {T<:Array{String}} = reset!(c,Labels(l))
    reset!(c::Clocks, l::Labels) = foreach(a -> if (value!(c,a) == (~,~,true))  getindex(c,findfirst(x -> x.label == l, c)).value = ClockValue(0) end, l)

    # passes time over clocks
    time_step!(c::Clocks, t::T) where {T<:Integer} = time_step!(c,UnitOfTime(t))
    time_step!(c::Clocks, t::UnitOfTime) = foreach(x -> x.value += t.value, c)

end