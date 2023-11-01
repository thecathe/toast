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
        action::Action
        resets::λ
        
        unfolded::Bool
        unfolded_str::String
        
        "Pop! head of Queue, then elevate to Act!"
        function Recv!(c::Social)
            @assert !isempty(c.queue) "Recv!, Queue cannot be empty."

            head = head!(c.queue;pop=true)
            action = Action(:recv,head)

            "Make Local Configuration."
            localised = Local(c)
            
            "Elevate to Act!"
            transition = TransitionLocal!(localised,action)

            act = transition.transition
            unfolded = transition.unfolded
            unfolded_str = transition.unfolded_str

            @assert act isa Act! "Recv!, act was unexpected type ($(typeof(act)))."

            "Bring back changes to Social Configuration."
            c.valuations = localised.valuations
            c.type = localised.type

            # act = Transition!(Local(c),a)
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