module ClockValuations

    import Base.show
    import Base.string
    import Base.iterate
    import Base.length
    import Base.getindex
    import Base.isempty

    using ..General
    using ..LogicalClocks
    using ..ClockConstraints

    
    
    # export Valuations, time_step!, value!, reset!, global_clock
    export Valuations, value!, global_clock

    const global_clock = Label("𝒢")
    
    # valuations
    mutable struct Valuations
        clocks::Clocks
        system::Clock

        Valuations() = new(Clocks(),Clock(global_clock,0))
        Valuations(system::Clock=Clock(global_clock,0)) = new(Clocks(),system)

        # provided clocks
        function Valuations(clocks::Clocks,system::Clock=Clock(global_clock,0)) 
            @assert !(system.label in labels(clocks)) "Global-system clock '$(system.label)' cannot be in local clocks: $(string(clocks))"
            
            new(clocks,system)
        end
    end
    Base.show(v::Valuations, io::Core.IO = stdout) = print(io, string(v))
    Base.show(v::Valuations, verbose::Bool, io::Core.IO = stdout) = print(io, string(v,verbose))
    Base.string(v::Valuations, verbose::Bool = true) = string(join(Labels([string(v.system), Labels([string(c) for c in v.clocks])...]), ", "))


    Base.length(v::Valuations) = length(v.clocks)
    Base.isempty(v::Valuations) = isempty(v.clocks)
    Base.getindex(v::Valuations, i::Int) = getindex(v.clocks, i)

    Base.iterate(v::Valuations) = isempty(v) ? nothing : (v[1], Int(1))
    Base.iterate(v::Valuations, i::Int) = (i >= length(v)) ? nothing : (v[i+1], i+1)



    export Value!, TimeStep!, Reset!

    
    # return value of valuation, using offset of global clock if necesary
    struct Value!
        v::ClockValue
        l::Label
        fresh::Bool
        function Value!(v::Valuations,l::Label)
            if l == v.system.label
                new(v.system.value, l, false)
            else
                new(value!(v.clocks,l,v.system.value)...)
            end
        end
    end
    Base.show(t::Value!,io::Core.IO = stdout) = print(io, string(t))
    Base.string(t::Value!) = string(string(Clock(t.l,t.v)), t.fresh ? "" : " (new)" )


    struct TimeStep!
        old::Clock
        v::Valuations
        t::TimeValue
        # TimeStep!(c::T,t::TimeValue) where {T<:Tuple{Clocks,S}} = TimeStep!(c.clocks,t)
        function TimeStep!(v,t)
            _old = Clock(global_clock,v.system.value)
            _t = TimeValue(t)
            v.system.value += _t.value
            time_step!(v.clocks,_t)
            new(_old,v,_t)
        end
    end
    Base.show(t::TimeStep!,io::Core.IO = stdout) = print(io, string(t))
    Base.string(t::TimeStep!) = string(string(t.old) , " -($(string(t.t)))> ", string(t.v))
    
    struct Reset!
        v::Valuations
        l::Labels
        function Reset!(v,l)
            _l = Labels(l)
            @assert !(v.system.label in l) "Global-system clock '$(v.system.label)' cannot be reset to 0!"
            # for each label a in l
            # if a value already exists for a
            # then set a to 0
            # (use value! of clock to ensure that any new clocks are initialised to 0)
            for a in l
                if value!(v.clocks,a,0)[3]
                    for x in v
                        if x.label == a
                            x.value = ClockValue(0)
                            break
                        end
                    end
                end
            end
            new(v,_l)
        end
    end
    Base.show(t::Reset!,io::Core.IO = stdout) = print(io, string(t))
    Base.string(t::Reset!) = string("[", string(t.l) , " -> 0]: ", string(t.v))


end