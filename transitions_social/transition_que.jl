module SocialTransitionQue

    import Base.show
    import Base.string
    
    using ..General
    using ..LogicalClocks
    using ..ClockValuations
    using ..SessionTypes
    using ..SessionTypeActions
    using ..Configurations

    export Que!

    struct Que!

        Que!(c::Social,d::Symbol,m::Msg,p::Labels=Labels([])) = Que!(c,Action(d,m,p))
        function Que!(c::Social,a::Action)
            @assert a.direction==:recv "Que!, action not recv: $(string(a))"
            # add message to queue
            push!(c.queue,a.msg)
        end
    end

end