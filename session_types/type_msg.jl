module TypeMsg

    import Base.show
    import Base.string

    using ..SessionTypes

    export Payload, SpecialPayload
    abstract type SpecialPayload end

    export None
    struct None <: SpecialPayload end
    Base.show(none::Type{None}, io::Core.IO = stdout) = print(io, string(none))
    Base.string(none::Type{None}) = string("None")

    const Payload = Union{SpecialPayload,String,Int,Bool}

    export Msg

    struct Msg 
        label::String
        payload::Type{T} where {T<:Payload}

        Msg(label::String,payload::Type{T} = None) where {T<:Payload} = new(label,payload)
    end

    Base.show(m::Msg, io::Core.IO = stdout) = print(io, string(m))

    function Base.string(m::Msg, mode::Symbol = :default) 
        if mode==:default
            string(string(m.label), m.payload isa Type{None} ? "" : "<$(string(m.payload))>")
        elseif mode==:full
            string("$(string(m.label))<$(string(m.payload))>")
        else
            @error "Msg.string, unexpected mode: $(string(mode))"
        end
    end
end