module Configurations

    import Base.show
    import Base.string
    import Base.convert
    
    using ..LogicalClocks
    using ..ClockConstraints
    using ..SessionTypes

    abstract type Configuration end

    struct Local <: Configuration
        clocks::Clocks
        type::T where {T<:SessionType}
        function Local(clocks,type)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"

            new(clocks,type)
        end
    end
    


    struct Social <: Configuration
        clocks::Clocks
        type::T where {T<:SessionType}
        queue::Msgs
        function Social(clocks,type)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"

            new(clocks,type,queue)
        end
    end


    
    struct System <: Configuration
        lhs::Social
        rhs::Social
        System(clocks,type) = new(clocks,type)
    end

end