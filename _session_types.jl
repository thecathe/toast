module SessionTypes

    import Base.convert
    import Base.show
    import Base.string

    import Base.iterate
    import Base.getindex
    import Base.lastindex

    import Base.push!


    using ..General
    using ..LogicalClocks
    using ..ClockConstraints

    abstract type SessionType end
    abstract type ActionType <: SessionType end
    abstract type RecursionType <: SessionType end

    # messages 
    export Msgs, Msg, Data, Delegation, ActionType

    abstract type Payload end

    # payload defs at end, after S

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



    




    


    

    

    # convert to msg
    Base.convert(::Type{Msg}, i::T) where {T<:Tuple{Label, X} where {X<:Payload}} = Msg(i[1],i[2])
    


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

    


    
    # allows for anonymous interaction types
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, End} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Interaction} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Choice} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Def} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Call} where {C<:Constraint, R<:Labels}} = Interaction(i...)

    # anonymous interactions with nested tails
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R, End}}} = Interaction(i...)
    
    # anonymous interactions with non-nested tails
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, End} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Interaction} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Choice} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Def} where {C<:Constraint, R<:Labels}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:Interaction where {T<:Tuple{Symbol, Msg, C, R, Call} where {C<:Constraint, R<:Labels}} = Interaction(i...)


    # allows for anonymous interactions within anonymous choices with vararg tails
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Vararg{P}} where {C<:Constraint, R<:Labels, P<:SessionType}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Array{P}} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R, Vararg{Q}} where Q<:SessionType}} = Interaction(i...)
    # Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Tuple{Symbol, Msg, C, R, Array{P}} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R, Vararg{Call}}}} = Interaction(i...)
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Vararg{P}}} where {C<:Constraint, R<:Labels, P<:SessionType}} = Choice([i...])


    # allows for anonymous choice declaration
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Interaction}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, End}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Interaction}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Choice}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Def}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, Call}} where {C<:Constraint, R<:Labels}} = Choice([i...])

    # allows for anonymous choices with anonymous interactions with nested tails
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R}}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:SessionType where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R, End}}} = Choice([i...])

    # allows for anonymous choices with anonymous interactions with non-nested tails
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, End}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Interaction}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Choice}} where {C<:Constraint, R<:Labels}} = Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Def}} where {C<:Constraint, R<:Labels}} =  Choice([i...])
    Base.convert(::Type{E}, i::T) where E<:Choice where {T<:Array{Tuple{Symbol, Msg, C, R, Call}} where {C<:Constraint, R<:Labels}} =  Choice([i...])



    
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



        
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R} where {C<:Constraint, R<:Labels}} = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, End} where {C<:Constraint, R<:Labels}}  = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Interaction} where {C<:Constraint, R<:Labels}}  = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Choice} where {C<:Constraint, R<:Labels}} = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Def} where {C<:Constraint, R<:Labels}} = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, Call} where {C<:Constraint, R<:Labels}} = new(c,:interaction)
        
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R}}}  = new(c,:interaction)
        S(c::T) where {T<:Tuple{Symbol, Msg, C, R, P} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R, End}}}  = new(c,:interaction)

        S(c::T) where {T<:Array{Interaction}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R}} where {C<:Constraint, R<:Labels}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, End}} where {C<:Constraint, R<:Labels}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Interaction}} where {C<:Constraint, R<:Labels}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Choice}} where {C<:Constraint, R<:Labels}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Def}} where {C<:Constraint, R<:Labels}} = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, Call}} where {C<:Constraint, R<:Labels}} = new(c,:choice)
        
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R}}}  = new(c,:choice)
        S(c::T) where {T<:Array{Tuple{Symbol, Msg, C, R, P}} where {C<:Constraint, R<:Labels, P<:Tuple{Symbol, Msg, C, R, End}}}  = new(c,:choice)
    end
    Base.show(s::S, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::S, mode::Symbol) = string(s.child, mode)
    Base.string(s::S) = string(s.child)



end