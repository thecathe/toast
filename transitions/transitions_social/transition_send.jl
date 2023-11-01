module SocialTransitionSend

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SocialTransition
    import ..Transitions.TransitionLocal!
    # using ..LocalTransitionAct
    import ..Transitions.Act!

    export Send!

    struct Send! <: SocialTransition
        success::Bool
        action::Union{Action,Nothing}
        resets::λ
        
        unfolded::Bool
        unfolded_str::String
        
        "Handle anonymous Actions."
        Send!(c::Social,a::T) where {T<:Tuple{Symbol,Msg}} = Send!(c,Action(a...))
        
        #
        function Send!(c::Social,a::Action)
            @assert a.direction.dir==:send "Send!, action not send: $(string(a))"
            
            "Make Local Configuration."
            localised = Local(c)

            "Elevate to Act!"
            # act = Act!(localised,a)
            transition = TransitionLocal!(localised,a)

            act = transition.transition
            unfolded = transition.unfolded
            unfolded_str = transition.unfolded_str

            @assert act isa Act! "Send!, act was unexpected type ($(typeof(act)))."

            "Bring back changes to Social Configuration."
            c.valuations = localised.valuations
            c.type = localised.type

            # act = Transition!(Local(c),a)
            new(act.success, act.action, act.resets, unfolded, unfolded_str)
        end

    end

    Base.show(l::Send!,io::Core.IO=stdout) = print(io,string(l))
    
    function Base.string(l::Send!) 
        if l.success
            string("⟶ $(string(l.action)) [$(string(l.resets)) ↦ 0]")
        else
            string("̸⟶ $(string(l.action))")
        end
    end

end