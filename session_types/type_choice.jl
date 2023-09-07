module TypeChoice

    import Base.show
    import Base.string
    import Base.length
    import Base.isempty
    import Base.getindex
    import Base.iterate

    using ..SessionTypes
    using ..TypeInteract

    export Choice

    mutable struct Choice <: SessionType
        children::Array{Interact}
        Choice(children::T) where {T<:Array{Interact}} = new(children)
        # single interact
        Choice(child::T) where {T<:Interact} = Choice([child])
    end

    Base.show(s::Choice, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::Choice, mode::Symbol, io::Core.IO = stdout) = print(io, string(s,mode))

    function Base.string(s::Choice, mode::Symbol = :default) 
        if mode==:default 
            string("{ ", join([string(c) for c in s.children], ", "), " }")
        elseif mode in [:full,:ext]
            string("{ ", join([string(c,mode) for c in s.children], ", "), " }")
        else
            @error "Choice.string, unexpected mode: $(string(mode))"
        end
    end         
    
    Base.length(s::Choice) = length(s.children)
    Base.isempty(s::Choice) = isempty(s.children)
    Base.getindex(s::Choice, i::Int) = getindex(s.children, i)

    Base.iterate(s::Choice) = isempty(s) ? nothing : (s[1], Int(1))
    Base.iterate(s::Choice, i::Int) = (i >= length(s)) ? nothing : (s[i+1], i+1)

end