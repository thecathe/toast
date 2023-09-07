module TypeRec

    import Base.show
    import Base.string

    using ..SessionTypes

    export μ

    mutable struct μ <: SessionType
        identity::String
        child::T where {T<:SessionType}
        μ(identity::String, child::T) where {T<:SessionType} = new(identity, child)
    end

    Base.show(s::μ, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::μ, mode::Symbol, io::Core.IO = stdout) = print(io, string(s, mode))

    Base.string(s::μ, mode::Symbol = :default) = string("μα[$(s.identity)].", mode in [:full,:ext] ? mode==:full ? string(s.child, mode) : string(s.child) : "§")

end