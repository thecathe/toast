module SessionTypes

    import Base.convert
    import Base.show
    import Base.string

    import Base.iterate
    import Base.getindex
    import Base.lastindex


    using ..General
    using ..LogicalClocks
    using ..ClockConstraints

    abstract type SessionType end
    abstract type ActionType <: SessionType end
    abstract type RecursionType <: SessionType end

    # messages 
    export Msgs, Msg, Data, Delegation, ActionType

    abstract type Payload end
    struct Delegation <: Payload 
        init::Constraint
        type::T where {T<:SessionType}
        Delegation(init,type) = new(init,type)
    end
    Base.show(m::Delegation, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Delegation) = string("(", string(m.init), ", ", string(m.type), ")")

    struct Data <: Payload
        child::DataType
        function Data(child) 
            supported_types = [String, Bool, Int]
            @assert child in supported_types "Data.child '$(string(child))' not in: $(string(supported_types))"

            new(child)
        end
    end
    Base.show(m::Data, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Data) = string(m.child)

    Base.convert(::Type{Payload},t::Type{T}) where {T<:Any} = Data(t)

    struct Msg
        label::Label
        payload::T where {T<:Payload}

        Msg(label,payload) = new(label,payload)
    end
    Base.show(m::Msg, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Msg) = string(m.label, "<", string(m.payload), ">")

    
    mutable struct Msgs
        children::Array{Msg}

        Msgs() = new(Array{Msg}([]))
        Msgs(children) = new(children)
    end
    Base.show(m::Msgs, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Msgs) = isempty(m) ? string("∅") : string(join([string(x) for x in m], ", "))

    Base.push!(m::Msgs, x::Msg) = push!(m.children, x)

    Base.length(m::Msgs) = length(m.children)
    Base.isempty(m::Msgs) = isempty(m.children)
    Base.getindex(m::Msgs, i::Int) = getindex(m.children, i)

    Base.iterate(m::Msgs) = isempty(m) ? nothing : (m[1], Int(1))
    Base.iterate(m::Msgs, i::Int) = (i >= length(m)) ? nothing : (m[i+1], i+1)



    # session types
    export SessionType, S, Choice, Interaction, End, Def, Call



    mutable struct Interaction <: ActionType
        direction::Symbol
        msg::Msg
        δ::δ
        λ::Labels
        child::T where {T<:SessionType}
        function Interaction(direction,msg,δ,λ,child=End())
            @assert direction in [:send, :recv]

            new(direction,msg,δ,λ,child)
        end
    end
    Base.show(s::Interaction, io::Core.IO = stdout) = print(io, string(s))
    function Base.string(s::Interaction, mode::Symbol = :default) 
        if mode==:default 
            string(s.direction==:send ? "!" : "?", " ", string(s.msg), " (", string(s.δ), ", ", string(s.λ), ").§")
        elseif mode==:full
            string(s.direction==:send ? "!" : "?", " ", string(s.msg), " (", string(s.δ), ", ", string(s.λ), ").",string(s.child,:full))
        elseif mode==:ext
            string(s.direction==:send ? "!" : "?", " ", string(s.msg), " (", string(s.δ), ", ", string(s.λ), ").",string(s.child))
        else
            @error "Interaction.string, unexpected mode: $(string(mode))"
        end
    end




    mutable struct Choice <: ActionType
        children::Array{Interaction}
        Choice(children) = new(Array{Interaction}(children))
    end
    Base.show(s::Choice, io::Core.IO = stdout) = print(io, string(s))
    function Base.string(s::Choice, mode::Symbol = :default) 
        if mode==:default 
            string("{ ", join([string(c) for c in s.children], ", "), " }")
        elseif mode in [:full,:ext]
            string("{ ", join([string(c,mode) for c in s.children], ", "), " }")
        else
            @error "Choice.string, unexpected mode: $(string(mode))"
        end
    end         
    
    Base.length(s::Choice) = length(s.children)
    Base.isempty(s::Choice) = isempty(s.children)
    Base.getindex(s::Choice, i::Int) = getindex(s.children, i)

    Base.iterate(s::Choice) = isempty(s) ? nothing : (s[1], Int(1))
    Base.iterate(s::Choice, i::Int) = (i >= length(s)) ? nothing : (s[i+1], i+1)


    struct End <: SessionType 
        End() = new()
    end
    Base.show(s::End, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::End, mode::Symbol = :default) = string("end")

    mutable struct Def <: RecursionType
        identity::String
        child::T where {T<:SessionType}
        Def(identity, S) = new(identity, S)
    end
    Base.show(s::Def, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Def, mode::Symbol = :default) = string("μα[$(s.identity)].", mode in [:full,:ext] ? mode==:full ? string(s.child, mode) : string(s.child) : "§")


    struct Call <: RecursionType
        identity::String
        iteration::UInt8
        Call(identity,iteration=0) = new(identity,iteration)
    end
    Base.show(s::Call, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Call, mode::Symbol = :default) = string("α[$(s.identity)]")


    # convert to msg
    Base.convert(::Type{Msg}, i::T) where {T<:Tuple{Label, Data}} = Msg(i[1],i[2])
    


    # allows for anonymous interaction types
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, End} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Interaction} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Choice} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Def} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Call} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)

    # anonymous interactions with nested tails
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R, End}}} = Interaction(i...)
    
    # anonymous interactions with non-nested tails
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, End} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Interaction} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Choice} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Def} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Call} where {C<:Constraint, R<:Array{Any}}} = Interaction(i...)


    # allows for anonymous interactions within anonymous choices with vararg tails
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Vararg{P}} where {C<:Constraint, R<:Array{Any}, P<:SessionType}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Array{P}} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R, Vararg{Q}} where Q<:SessionType}} = Interaction(i...)
    # Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Array{P}} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R, Vararg{Call}}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Vararg{P}}} where {C<:Constraint, R<:Array{Any}, P<:SessionType}} = Choice([i...])


    # allows for anonymous choice declaration
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Interaction}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, End}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Interaction}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Choice}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Def}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Call}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])

    # allows for anonymous choices with anonymous interactions with nested tails
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R, End}}} = Choice([i...])

    # allows for anonymous choices with anonymous interactions with non-nested tails
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, End}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Interaction}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Choice}} where {C<:Constraint, R<:Array{Any}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Def}} where {C<:Constraint, R<:Array{Any}}} =  Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Call}} where {C<:Constraint, R<:Array{Any}}} =  Choice([i...])


    
    mutable struct S <: SessionType
        child::T where {T<:SessionType}
        kind::Symbol

        S(c::T) where {T<:Interaction} = new(c,:interaction)
        S(c::T) where {T<:Choice} = new(c,:choice)
        S(c::T) where {T<:Def} = new(c,:def)
        S(c::T) where {T<:Call} = new(c,:call)
        S(c::T) where {T<:End} = new(c,:end)
        
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R} where {C<:Constraint, R<:Array{Any}}} = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, End} where {C<:Constraint, R<:Array{Any}}}  = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Interaction} where {C<:Constraint, R<:Array{Any}}}  = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Choice} where {C<:Constraint, R<:Array{Any}}} = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Def} where {C<:Constraint, R<:Array{Any}}} = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Call} where {C<:Constraint, R<:Array{Any}}} = new(c,:interaction)
        
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R}}}  = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R, End}}}  = new(c,:interaction)

        S(c::T) where {T<:Array{Interaction}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R}} where {C<:Constraint, R<:Array{Any}}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, End}} where {C<:Constraint, R<:Array{Any}}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Interaction}} where {C<:Constraint, R<:Array{Any}}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Choice}} where {C<:Constraint, R<:Array{Any}}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Def}} where {C<:Constraint, R<:Array{Any}}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Call}} where {C<:Constraint, R<:Array{Any}}} = new(c,:choice)
        
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R}}}  = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Array{Any}, P<:Tuple{Symbol, Msg, C, R, End}}}  = new(c,:choice)
    end
    Base.show(s::S, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::S, mode::Symbol) = string(s.child, mode)
    Base.string(s::S) = string(s.child)


    export Dual

    struct Dual <: SessionType
        child::T where {T<:SessionType}
        kind::Symbol

        Dual(c::T) where {T<:S} = Dual(c.child)
        
        Dual(c::T) where {T<:Def} = new(c,:def)
        Dual(c::T) where {T<:Call} = new(c,:call)
        Dual(c::T) where {T<:End} = new(c,:end)
        
        # Dual(c::T) where {T<:Interaction} = new(Interaction((c.direction == :send) ? :recv : :send, c[2:end]...),:interaction)
        Dual(c::T) where {T<:Interaction} = new(Interaction((c.direction == :send) ? :recv : :send, c.msg, c.δ, c.λ, c.S),:interaction)

        Dual(c::T) where {T<:Choice} = new(Choice([Interaction((i.direction == :send) ? :recv : :send, i.msg, i.δ, i.λ, i.S) for i in c]),:choice)

    end
    Base.show(s::Dual, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Dual) = string(s.child)

    # convert back to s
    Base.convert(::Type{S}, s::T) where {T<:Dual} = S(s.child)

end