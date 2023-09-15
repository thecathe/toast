module TypeDuality

    import Base.show
    import Base.string

    using ..SessionTypes

    export Duality

    struct Duality <: SessionType
        type::T where {T<:SessionType}
        dual::Q where {Q<:SessionType}

        Duality(type::T) where {T<:End} = new(type,type)
        Duality(type::T) where {T<:α} = new(type,type)

        Duality(type::T) where {T<:μ} = new(type,μ(type.identity,Duality(type.child).dual))

        Duality(type::T) where {T<:Interact} = new(type, Interact(dual(type.direction), type.msg, type.constraints, type.resets, Duality(type.child).dual))

        Duality(type::T) where {T<:Choice} = new(type, Choice([Duality(i).dual for i in type.children]))

        
    end

    Base.show(s::Duality, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::Duality, mode::Symbol, io::Core.IO = stdout) = print(io, string(s, mode))
    
    function Base.string(s::Duality, mode::Symbol = :default) 
        if mode in [:default,:tail,:full,:expanded]
            return string(s.dual)
        elseif mode==:fancy
            return string("$(string(s.type,:default)) ⇒ $(string(s.dual,:default))")
        elseif mode==:fancy_full
            return string("$(string(s.type,:full)) ⇒ $(string(s.dual,:full))")
        elseif mode==:fancy_expanded
            return string("$(string(s.type,:expanded)) ⇒ $(string(s.dual,:expanded))")
        else
            @error "Duality.show, unexpected mode: $(string(mode))"
        end
    end
    
    dual(direction::Direction) = Direction(direction.child==:send ? :recv : :send)
end