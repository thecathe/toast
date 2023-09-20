module ClockResets

    import Base.show
    import Base.string

    import Base.length
    import Base.isempty
    
    import Base.getindex
    import Base.iterate

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

    
    Base.length(resets::λ) = length(resets.children)
    Base.isempty(resets::λ) = isempty(resets.children)
    Base.getindex(resets::λ, i::Int) = getindex(resets.children, i)

    Base.iterate(resets::λ) = isempty(resets) ? nothing : (resets[1], Int(1))
    Base.iterate(resets::λ, i::Int) = (i >= length(resets)) ? nothing : (resets[i+1], i+1)


end