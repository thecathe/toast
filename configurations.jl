module Configurations

    import Base.show
    import Base.string
    import Base.convert
    import Base.iterate
    
    using ..General
    using ..LogicalClocks
    using ..ClockConstraints
    using ..SessionTypes
    using ..ClockValuations


    export Configuration, Local, Social, System

    # configurations

    abstract type Configuration end

    struct Local <: Configuration
        valuations::Valuations
        # type::T where {T<:SessionType}
        type::S
        function Local(valuations,type)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"
            new(valuations,type)
        end
    end
    Base.show(c::Local, io::Core.IO = stdout) = print(io, string(c))
    Base.string(c::Local)= string("(", join([string(c.valuations),string(c.type)],", "), ")")
    

    struct Social <: Configuration
        valuations::Valuations
        # type::T where {T<:SessionType}
        type::S
        queue::Msgs
        function Social(clocks,type,queue)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"
            new(clocks,type,queue)
        end
    end
    Base.show(c::Social, io::Core.IO = stdout) = print(io, string(c))
    Base.string(c::Social)= string("(", join([string(c.valuations),string(c.type),string(c.queue)],", "), ")")
    

    # from social to local configurations
    Base.convert(::Type{Local}, c::T) where {T<:Social} = Local(c.valuations,c.type)

    
    isend(c::Local) = (typeof(c.type) == End) ? true : false
    isend(c::Social) = (typeof(c.type) == End) ? true : false


    struct System <: Configuration
        lhs::Social
        rhs::Social
        System(lhs,rhs) = new(lhs,rhs)
    end
    Base.show(c::System, io::Core.IO = stdout) = string(io, c)
    function Base.string(c::System, verbose::Bool = false)
        string("(", join([string(c.lhs,verbose),string(c.rhs,verbose)]," ∣ "), ")")
    end

    # construct system from array of 2 social
    function Base.convert(::Type{System}, t::T) where {T<:Array{Social}} 
        @assert length(t) == 2
        System(t[1],t[2])
    end

    Base.convert(::Type{System}, t::T) where {T<:Tuple{Social,Social}} = System(t[1],t[2])
    

    # get system as children
    Base.convert(::Type{Array{Social}}, t::System) = Array{Social}([t.lhs,t.rhs])


end