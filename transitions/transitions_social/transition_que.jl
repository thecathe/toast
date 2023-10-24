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
        label::Label
        Que!(c::Social,d::Symbol,m::Msg,p::Labels=Labels([])) = Que!(c,Action(d,m,p))
        function Que!(c::Social,a::Action)
            @assert a.direction==:recv "Que!, action not recv: $(string(a))"
            # add message to queue
            push!(c.queue,a.msg)

            new(Label(string(a)))
        end
    end
    Base.show(l::Que!,io::Core.IO=stdout) = print(io,string(l))
    function Base.string(l::Que!) 
        if l.success
            string("⟶ $(string(l.label))")
        else
            string("̸⟶ $(string(l.label))")
        end
    end

end