module SocialTransitionQue

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SocialTransition

    export Que!

    struct Que! <: SocialTransition
        success::Bool
        action::Action

        "Handle anonymous Actions."
        Que!(c::Social,a::T) where {T<:Tuple{Symbol,Msg}} = Que!(c,Action(a...))
        

        function Que!(c::Social,a::Action)
            @assert a.direction.dir==:recv "Que!, action not recv: $(string(a))"
            # add message to queue
            push!(c.queue,a.msg)

            new(true,a)
        end
    end

    Base.show(l::Que!,io::Core.IO=stdout) = print(io,string(l))
    
    function Base.string(l::Que!) 
        if l.success
            string("⟶ $(string(l.action))")
        else
            string("̸⟶ $(string(l.action))")
        end
    end

end