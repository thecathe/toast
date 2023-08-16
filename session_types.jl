module SessionTypes

    import Base.convert
    import Base.show
    import Base.string


    using ..General
    using ..LogicalClocks
    using ..ClockConstraints

    abstract type SessionType end

    # messages 
    export Msgs, Msg, Data, Delegation

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

    
    struct Msgs
        children::Array{Msg}
        Msgs(children) = new(children)
    end
    Base.show(m::Msgs, io::Core.IO = stdout) = print(io, string(m))
    Base.string(m::Msgs) = string(join([string(x) for x in m], ", "))

    Base.push!(m::Msgs, x::Msg) = push!(m.children, x)

    Base.length(m::Msgs) = length(m.children)
    Base.isempty(m::Msgs) = isempty(m.children)
    Base.getindex(m::Msgs, i::Int) = getindex(m.children, i)

    Base.iterate(m::Msgs) = isempty(c) ? nothing : (m[1], Int(1))
    Base.iterate(m::Msgs, i::Int) = (i >= length(c)) ? nothing : (m[i+1], i+1)



    # session types
    export SessionType, S, Choice, Interaction, End, Def, Call

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
    Base.string(s::Interaction, verbose::Bool = false) = string((s.direction == :send) ? "!" : "?", " ", string(s.msg), " (", string(s.δ), ", ", string(s.λ), ").", verbose ? string(s.S) : string("S"))

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
    function Base.string(s::Choice, verbose::Bool = false) 
        if verbose && length(s) > 1
            string("{\n ", join([string(" ", string(c)) for c in s.children], ",\n "), "\n}")
        else
            string("{ ", join([string(c) for c in s.children], ", "), " }")
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
        S::T where {T<:SessionType}
        Def(identity, S) = new(identity, S)
    end
    Base.show(s::Def, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Def, verbose::Bool = false) = string("μα[$(s.identity)].", verbose ? string(s.S) : string("S"))

    # convert when tail is Def
    Base.convert(::Type{Interaction}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}, Def}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ), i[5])

    # convert within S with tail
    Base.convert(::Type{SessionType}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}, Def}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ), i[5])



    struct Call <: SessionType
        identity::String
        Call(identity) = new(identity)
    end
    Base.show(s::Call, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Call) = string("α[$(s.identity)]")

    # convert when tail is Call
    Base.convert(::Type{Interaction}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}, Call}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ), i[5])

    # convert within S with tail
    Base.convert(::Type{SessionType}, i::T) where {T<:Tuple{Symbol, Msg, Constraint, Array{Any}, Call}} = Interaction(i[1], i[2], i[3], (isempty(i[4]) ? Array{Label}[] : Array{Label}(i[4]) ), i[5])

end