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
        _del::Q where {Q<:SpecialPayload}

        Msg(label::String,payload::Type{T} = None) where {T<:Payload} = new(label,payload,None())

        # delegation
        function Msg(label::String,payload::T = None) where {T<:SpecialPayload}
            if payload isa None
                # same as default
                new(label,payload,None())
            else
                # must be delegation
                new(label,Del,payload)
            end
        end
    end

    Base.show(m::Msg, io::Core.IO = stdout) = print(io, string(m))

    function Base.string(m::Msg, mode::Symbol = :default) 
        # get payload type
        if m.payload isa Type{Del}
            str_payload = string(m._del)
        elseif m.payload isa Type{None}
            str_payload = mode==:default ? "" : "<None>"
        elseif m.payload isa Type{String}
            str_payload = mode==:default ? "" : "<String>"
        elseif m.payload isa Type{Int}
            str_payload = mode==:default ? "" : "<Int>"
        elseif m.payload isa Type{Bool}
            str_payload = mode==:default ? "" : "<Bool>"
        else
            @error "Msg.string, unexpected payload type: $(m.payload)"
        end

        if mode in [:default,:full]
            string(string(m.label),str_payload)
        else
            @error "Msg.string, unexpected mode: $(string(mode))"
        end
    end
end