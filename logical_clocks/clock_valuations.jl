module ClockValuations

    import Base.show
    import Base.string

    using ..LogicalClocks

    export Valuations, ValueOf!, ResetClocks!, TimeStep!

    mutable struct Valuations
        clocks::Array{Clock}
        system::Clock
        #
        Valuations(children::T,offset::Num = 0) where {T<:Array{Clock}} = new(children,Clock("𝒢",UInt8(offset)))
        # empty
        Valuations() = Valuations(Array{Clock}([]))
        # single
        Valuations(child::Clock) = Valuations(Array{Clock}([child]))
        # anonymous clock
        Valuations(child::T,offset::Num = 0) where {T<:Tuple{String,Num}} = Valuations(Array{Clock}([Clock(c...)]), offset)
        # anonymous clocks
        Valuations(children::Array{T},offset::Num = 0) where {T<:Tuple{String,Num}} = Valuations(Array{Clock}([Clock(c...) for c in children]), offset)
    end

    Base.show(t::Valuations, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::Valuations, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::Valuations, mode::Symbol = :default)
        if mode==:default
            string(join([string(v) for v ∈ [t.system,t.clocks...]], ", "))
        else
            @error "TimeStep!.string, unexpected mode: $(string(t))"
        end
    end

    #
    # value
    #
    struct ValueOf!
        label::String
        value::UInt8

        function ValueOf!(v::Valuations,label::String) 
            for c ∈ v.clocks
                if c.label==label
                    return new(label,c.value)
                end
            end
            
            # new clock
            push!(v.clocks,Clock(label,0))
            new(label,0)
        end
    end

    Base.show(t::ValueOf!, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::ValueOf!, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::ValueOf!, mode::Symbol = :default)
        if mode==:default
            string("($(string(t.label)):$(string(t.value)))")
        else
            @error "ValueOf!.string, unexpected mode: $(string(t))"
        end
    end

    #
    # resets
    #
    struct ResetClocks!
        resets::Array{String}
        #
        ResetClocks!(v::Valuations,label::String) = ResetClocks!(v,Array{String}([label]))
        #
        function ResetClocks!(v::Valuations,resets::T) where {T<:Array{String}}
            reset = Array{String}([])
            for c ∈ v.clocks
                if c.label ∈ resets
                    c.value = 0
                    push!(reset,c.label)
                end
            end
            # check for non-existant clocks
            for l ∈ resets
                if l ∉ reset
                    push!(v.clocks,Clock(l,v.global_clock))
                end
            end
            new(resets)
        end
    end

    Base.show(t::ResetClocks!, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::ResetClocks!, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::ResetClocks!, mode::Symbol = :default)
        if mode==:default
            string("[{$(join([string(r) for r in t.resets],","))}↦ 0]")
        else
            @error "ResetClocks!.string, unexpected mode: $(string(t))"
        end
    end

    #
    # time step
    #
    struct TimeStep!
        value::UInt8
        #
        TimeStep!(v::Valuations,t::Num) = TimeStep!(v,UInt8(t))
        #
        function TimeStep!(v::Valuations,t::UInt8) 
            foreach(x -> x.value += t, v.clocks)
            v.system.value += t
            new(t)
        end
    end
    
    Base.show(t::TimeStep!, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::TimeStep!, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::TimeStep!, mode::Symbol = :default)
        if mode==:default
            string("⟶ (t=$(string(t.value)))⟶")
        else
            @error "TimeStep!.string, unexpected mode: $(string(t))"
        end
    end
end