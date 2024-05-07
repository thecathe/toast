module SocialTransitionRecv

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SocialTransition
    import ..Transitions.TransitionLocal!
    import ..Transitions.Act!

    export Recv!

    struct Recv! <: SocialTransition
        success::Bool
        action::Union{Action,Nothing}
        resets::λ
        
        unfolded::Bool
        unfolded_str::String
        
        "Pop! head of Queue, then elevate to Act!"
        function Recv!(c::Social)

            "Get head of message queue."
            head = head!(c.queue;pop=false)

            "Check if message in queue."
            if !head[2]
                @debug "Recv! no message in queue."
                return new(false,Nothing(),λ(),false,"")
            end

            "Get Action label (:recv, head_of_queue)."
            action = Action(:recv,head[1])

            "Make Local Configuration."
            localised = Local(c)

            "Elevate to Act!"
            transition = TransitionLocal!(localised,action)
            
            "If success, then pop message from top of queue."
            if transition.success
                head!(c.queue;pop=true)
            end

            act = transition.transition
            unfolded = transition.unfolded
            unfolded_str = transition.unfolded_str

            @assert act isa Act! "Recv!, act was unexpected type ($(typeof(act)))."

            "Bring back changes to Social Configuration."
            c.valuations = localised.valuations
            c.type = localised.type

            new(act.success, act.action, act.resets, unfolded, unfolded_str)
        end
    end

    Base.show(l::Recv!,io::Core.IO=stdout) = print(io,string(l))
    
    function Base.string(l::Recv!) 
        if l.success
            string("⟶ $(string(l.action))")
        else
            string("̸⟶ $(string(l.action))")
        end
    end

end