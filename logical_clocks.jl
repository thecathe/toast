module LogicalClocks

    import Base.show
    import Base.string
    import Base.convert
    import Base.iterate
    import Base.length
    import Base.getindex
    import Base.push!
    import Base.isempty

    export Clocks

    mutable struct Clocks
        children::Array{Clock}
        Clocks(children) = new(children)
    end
    Base.show(c::Clocks, io::Core.IO = stdout) = print(io, string(c))
    Base.string(c::Clocks) = string([string(x) for x in c])

    Base.length(c::Clocks) = length(c.children)
    Base.isempty(c::Clocks) = isempty(c.children)
    Base.getindex(c::Clocks, i::int) = getindex(c.children, i)

    Base.iterate(c::Clocks) = isempty(c) ? nothing : (c[1], Int(1))
    Base.iterate(c::Clocks, i::Int) = (i >= length(c)) ? nothing : (c[i+1], i+1)

    export Constraint, C

    module Constraints
        export Constraint, C

        using ..Clocks

        abstract type Constraint end

        struct C <: Constraint end
        Base.string(c::C) = string("δ")
    end
    
    using .Constraints

end