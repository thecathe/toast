module LocalTransitionAct

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.LocalTransition

    export Act!

    struct Act! <: LocalTransition
        # old_config::Local
        success::Bool
        action::Action
        resets::λ

        "Handle anonymous Actions."
        Act!(c::Local,a::T) where {T<:Tuple{Symbol,Msg}} = Act!(c,Action(a...))
        # 
        Act!(c::Local,action::Action) = Act!(c,c.type,action)
        
        "Act! within a Choice."
        function Act!(c::Local,choice::Choice,action::Action) 
            # old_config = c
            _c = deepcopy(c)
            "Search for corresponding Interact in Choice."
            for interact in choice
                @debug "[act] choice, testing: $(string(interact))."
                act = Act!(_c,interact,action)
                "Interact successful?"
                if act.success
                    c.valuations = _c.valuations
                    c.type = _c.type
                    return act
                end
            end

            @debug "[act] Loop finished and no interact found."
            # new(old_config,false,action,[])
            new(false,action,λ())
        end
        #
        function Act!(c::Local,interact::Interact,action::Action)
            # old_config = c

            "Check if actions match."
            interact_action = Action(interact)
            if interact_action.direction.dir==action.direction.dir && interact_action.msg.label==action.msg.label && typeof(interact_action.msg.payload)==typeof(action.msg.payload)
                "Resets of interaction."
                resets = interact.resets
                "Check if constraints satisfied."
                evaluation = Evaluate!(c.valuations,interact)
                @debug "[act] ($(string(interact_action))), evaluate: $(string(evaluation,:full,:expand))."
                if evaluation.enabled
                    "Reset Clocks."
                    ResetClocks!(c.valuations,resets)

                    "Update Configuration type."
                    c.type = interact.child
                    
                    "Constraints satisfied, clocks reset, and type progressed."
                    # return new(old_config,true,action,resets)
                    @debug "[act] ($(string(action))) success!"
                    return new(true,action,resets)
                else
                    "Constraints not satisfied, do nothing."
                    @debug "[act] ($(string(interact_action))), constraints not satisfied: $(string(evaluation,:full,:expand))."
                    # return new(old_config,false,action,resets)
                    return new(false,action,resets)
                end
            else
                @debug "[act] actions do not match: $(string(interact_action)) ≠ $(string(action))...\n\t(dirs: $(interact_action.direction.dir==action.direction.dir))\n\t(label: $(interact_action.msg.label==action.msg.label))\n\t(payload: $(typeof(interact_action.msg.payload)==typeof(action.msg.payload)))."
            end
            "Interaction not able to act."
            new(false,action,λ())
        end
    end

    Base.show(l::Act!,io::Core.IO=stdout) = print(io,string(l))

    function Base.string(l::Act!) 
        if l.success
            string("⟶ $(string(l.action)) [$(string(l.resets)) ↦ 0]")
        else
            string("̸⟶ $(string(l.action))")
        end
    end

end