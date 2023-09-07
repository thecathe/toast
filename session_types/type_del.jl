module TypeDel

    import Base.show
    import Base.string

    using ...LogicalClocks

    using ..SessionTypes

    export Del

    mutable struct Del <: SpecialPayload
        init::δ
        type::T where {T<:SessionType}
        Del(init::δ,type::T) where {T<:SessionType} = new(init,type)
    end
    Base.show(s::Del, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Del, mode::Symbol = :default) = string("($(string(s.init)), $(string(s.type)))")

end