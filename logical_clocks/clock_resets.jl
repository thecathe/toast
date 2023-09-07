module ClockResets

    import Base.show
    import Base.string

    export λ
    struct λ
        children::T where {T<:Array{String}}
        # empty resets
        λ() = new(Array{String}([]))
        # single reset
        λ(child::String) = λ([child])
        # 
        λ(children::T) where {T<:Array{String}} = new(children)
    end

    Base.show(resets::λ, io::Core.IO = stdout) = print(io, string(resets))

    function Base.string(resets::λ, mode::Symbol = :default)
        if mode==:default
            if isempty(resets.children)
                return string("∅")
            else
                return string("{$(join(resets.children, ", "))}")
            end
        else
            @error "λ.string, unexpected mode: $(string(mode))"
        end
    end

end