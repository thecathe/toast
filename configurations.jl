module Configurations

    import Base.show
    import Base.string
    import Base.convert
    
    using ..General
    using ..LogicalClocks
    using ..ClockConstraints
    using ..SessionTypes
    using ..ClockValuations


    # configurations

    abstract type Configuration end

    struct Local <: Configuration
        valuations::Valuations
        type::T where {T<:SessionType}
        function Local(clocks,type)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"
            new(clocks,type)
        end
    end
    Base.show(c::Local, io::Core.IO = stdout) = string(io, c)
    function Base.string(c::Local, verbose::Bool = false)
        string("(", join([string(c.clocks, verbose),string(c.type, verbose)],", "), ")")
    end


    struct Social <: Configuration
        valuations::Valuations
        type::T where {T<:SessionType}
        queue::Msgs
        function Social(clocks,type,queue)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"
            new(clocks,type,queue)
        end
    end
    Base.show(c::Social, io::Core.IO = stdout) = string(io, c)
    function Base.string(c::Local, verbose::Bool = false)
        string("(", join([string(c.clocks, verbose),string(c.type, verbose),string(c.queue, verbose)],", "), ")")
    end

    # from social to local configurations
    Base.convert(::Type{Local}, c::T) where {T<:Social} = Local(c.valuations,c.type)

    
    struct System <: Configuration
        lhs::Social
        rhs::Social
        System(lhs,rhs) = new(lhs,rhs)
    end
    Base.show(c::System, io::Core.IO = stdout) = string(io, c)
    function Base.string(c::System, verbose::Bool = false)
        string("(", join([string(c.lhs,verbose),string(c.rhs,verbose)]," ∣ "), ")")
    end

    # 

end