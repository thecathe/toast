module SessionTypes

    import Base.convert
    import Base.show
    import Base.string

    import ..Clocks.Constraint

    abstract type SessionType end

    const Label = String 
    const Labels = Array{Label}

    Base.string(l::Labels) = isempty(l) ? string("∅") : string("{", join(l), "}")

    # messages 
    export Msg, Data, Delegation

    abstract type Payload end
    struct Delegation <: Payload 
        init::Constraint
        type::SessionType
        Delegation(init,type) = new(init,type)
    end
    Base.show(m::Delegation, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Delegation) = string("(", string(m.init), ", ", string(m.type), ")")

    struct Data <: Payload
        child::T where {T<:Union{String,Number}}
        Data(child) = new(child)
    end
    Base.show(m::Data, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Data) = string(m.child)

    struct Msg 
        label::Label
        payload::Payload
        Msg(label,payload) = new(label,payload)
    end
    Base.show(m::Msg, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Msg) = string(m.label, "<", string(m.payload), ">")


    # session types
    export S, Choice, Interaction, End

    struct Interaction <: SessionType
        direction::Symbol
        msg::Msg
        δ::Constraint
        λ::Array{Label}
        S::T where {T<:SessionType}
        function Interaction(direction,msg,δ,λ,S=End())
            @assert direction in [:send, :recv]

            new(direction,msg,δ,λ,S)
        end
    end
    Base.show(s::Interaction, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Interaction) = string((s.direction == :send) ? "!" : "?", " ", string(s.msg), " (", string(s.δ), ", ", string(s.λ), ").", string(s.S))

    Base.convert(::Type{Interaction}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ))



    struct S <: SessionType
        child::SessionType
        # S(child::SessionType) = Expr(:S, child)
        S(child) = new(child)
    end
    Base.show(s::S, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::S) = string(s.child)

    struct Choice <: SessionType
        children::Array{Interaction}
        # Choice(children) = Expr(:Choice, children)
        Choice(children) = new(children)
    end
    Base.show(s::Choice, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Choice) = string("{", [string(c) for c in s.children], "}")


    struct End <: SessionType end
    Base.show(s::End, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::End) = "end"

end