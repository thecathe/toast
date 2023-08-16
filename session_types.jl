module SessionTypes

    import Base.convert
    import Base.show
    import Base.string

    import ..Clocks.Constraint

    abstract type SessionType end

    const Label = String 
    const Labels = Array{Label}
    Base.convert(::Type{Array{Label}}, l::T) where {T<:Vector{Any}} = Array{Label}(l)

    Base.string(l::Labels) = isempty(l) ? string("∅") : string("{", join(l), "}")

    # messages 
    export Msg, Data, Delegation

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

    # convert within Choice
    Base.convert(::Type{Interaction}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ))
    
    # convert within Choice with tail
    Base.convert(::Type{Interaction}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}, Tuple}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ), Interaction(i[5]...))

    # convert within S
    Base.convert(::Type{SessionType}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ))

    # convert within S with tail
    Base.convert(::Type{SessionType}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}, Tuple}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ), Interaction(i[5]...))


    struct S <: SessionType
        child::T where {T<:SessionType}
        S(child) = new(child)
    end
    Base.show(s::S, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::S) = string(s.child)


    struct Choice <: SessionType
        children::Array{Interaction}
        Choice(children) = new(children)
    end
    Base.show(s::Choice, io::Core.IO = stdout) = print(io, string(s))
    function Base.string(s::Choice) 
        if length(s) <= 1
            string("{ ", join([string(c) for c in s.children], ", "), " }")
        else
            string("{\n ", join([string(" ", string(c)) for c in s.children], ",\n "), "\n}")
        end
    end         
    
    Base.length(s::Choice) = length(s.children)

    # convert when tail is Choice
    Base.convert(::Type{Interaction}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}, Choice}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ), i[5])


    struct End <: SessionType 
        End() = new()
    end
    Base.show(s::End, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::End) = "end"

    struct Def <: SessionType
        identity::String
        child::T where {T<:SessionType}
        Def(identity, child) = new(identity, child)
    end
    Base.show(s::Def, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Def) = string("μα\^$(s.identity).", string(s.child))

    struct Call <: SessionType
        identity::String
        Call(identity) = new(identity)
    end
    Base.show(s::Call, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Call) = string("α\^$(s.identity)")

end