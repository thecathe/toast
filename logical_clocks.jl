module LogicalClocks

    import Base.show
    import Base.string
    import Base.convert

    import Base.iterate

    import Base.length
    import Base.getindex
    import Base.push!
    import Base.isempty
    
    using ..General

    export Clocks, Clock, ClockValue, TimeValue
    export value!, reset!, time_step!, labels

    const ClockValue = UInt8
    struct TimeValue 
        value::T where {T<:Real}
        function TimeValue(value)
            @assert value>=0 "Time values must be greater or equal to 0: '$(value)' is invalid."
            new(value)
        end
    end
    Base.string(t::TimeValue) = string(t.value)
    Base.convert(::Type{TimeValue}, t::T) where {T<:Number} = TimeValue(t)


    mutable struct Clock
        label::Label
        value::ClockValue
        Clock(label,value) = new(label,value)
    end
    Base.show(c::Clock, io::Core.IO = stdout) = print(io, string(c))
    Base.show(c::Clock, verbose::Bool = false) = print(string(c,verbose))
    Base.string(c::Clock) = string("[", c.label, ": ", c.value, "]")

    Base.convert(::Type{Clock}, c::T) where {T<:Tuple{String, Num}} = Clock(c[1], c[2])
    Base.convert(::Type{Clock}, c::T) where {T<:Tuple{Num, String}} = Clock(c[2], c[1])

    struct Clocks
        children::Array{Clock}
        Clocks(children) = new(children)
    end
    Base.show(c::Clocks, io::Core.IO = stdout) = print(io, string(c))
    function Base.string(c::Clocks, verbose::Bool = true) 
        verbose ? string(join([string(x) for x in c], ", ")) : string("Clocks($(length(c)))")
    end

    Base.push!(c::Clocks, x::Clock) = push!(c.children, x)

    Base.length(c::Clocks) = length(c.children)
    Base.isempty(c::Clocks) = isempty(c.children)
    Base.getindex(c::Clocks, i::Int) = getindex(c.children, i)

    Base.iterate(c::Clocks) = isempty(c) ? nothing : (c[1], Int(1))
    Base.iterate(c::Clocks, i::Int) = (i >= length(c)) ? nothing : (c[i+1], i+1)

    labels(c::Clocks) = Labels([x.label for x in c.children])
    
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
    Base.string(val::Tuple{ClockValue,Label,Bool}, verbose::Bool = false) = string(string(Clock(val[2],val[1])), val[3] && verbose ? "" : " *fresh*")

    # resets clocks with labels to 0
    reset!(c::Clocks, l::Array{Any}) = reset!(c,Labels(l))
    reset!(c::Clocks, l::Labels) = foreach(a -> if (value!(c,a) == (~,~,true))  getindex(c,findfirst(x -> x.label == l, c)).value = ClockValue(0) end, l)

    # passes time over clocks
    time_step!(c::Clocks, t::T) where {T<:Integer} = time_step!(c,TimeValue(t))
    time_step!(c::Clocks, t::TimeValue) = foreach(x -> x.value += t.value, c)

end