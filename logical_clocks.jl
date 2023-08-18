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
    export clock_value!, reset_clocks!, time_pass!, labels

    const ClockValue = UInt8
    struct TimeValue 
        value::T where {T<:Real}
        function TimeValue(value)
            @assert value>=0 "Time values must be greater or equal to 0: '$(value)' is invalid."
            new(value)
        end
    end
    Base.convert(::Type{TimeValue}, t::T) where {T<:Number} = TimeValue(t)


    mutable struct Clock
        label::Label
        value::ClockValue
        Clock(label,value) = new(label,value)
    end
    Base.show(c::Clock, io::Core.IO = stdout) = print(io, string(c))
    Base.show(c::Clock, verbose::Bool = false) = print(string(c,verbose))
    Base.string(c::Clock) = string("[", c.label, ": ", c.value, "]")

    Base.convert(::Type{Clock}, c::T) where {T<:Tuple{String, Int}} = Clock(c[1], c[2])

    struct Clocks
        children::Array{Clock}
        Clocks(children) = new(children)
    end
    Base.show(c::Clocks, io::Core.IO = stdout) = print(io, string(c))
    function Base.string(c::Clocks, verbose::Bool = false) 
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
    function clock_value!(c::Clocks, l::Label, offset = ClockValue(0)::ClockValue)
        if l in labels(c)
            values = findall(x -> x.label == l, c.children)
            @assert length(values) == 1 "More than one clock named '$(l)' in: $(show(c))."
            return (ClockValue(first(values)), l, true)
        else
            push!(c, Clock(l, offset))
            return (ClockValue(0), l, false)
        end
    end

    # show value correctly
    Base.show(val::Tuple{ClockValue,Label,Bool},io::Core.IO = stdout) = print(io, string(val))
    Base.string(val::Tuple{ClockValue,Label,Bool}, verbose::Bool = false) = string(string(Clock(val[2],val[1])), val[3] && verbose ? "" : " *fresh*")

    # resets clocks with labels to 0
    reset_clocks!(c::Clocks, l::Array{Any}) = reset_clocks!(c,Labels(l))
    reset_clocks!(c::Clocks, l::Labels) = foreach(a -> if (clock_value!(c,a) == (~,~,true))  getindex(c,findfirst(x -> x.label == l, c)).value = ClockValue(0) end, l)

    # passes time over clocks
    time_pass!(c::Clocks, t::T) where {T<:Integer} = time_pass!(c,TimeValue(t))
    time_pass!(c::Clocks, t::TimeValue) = foreach(x -> x.value += t.value, c)

end