module LocalTransitionAct

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    export Act!

    struct Act!
        # old_config::Local
        success::Bool
        action::Action
        resets::λ
        #
        Act!(c::Local,a::T) where {T<:Tuple{Symbol,Msg}} = Act!(c,Action(a...))
        # 
        function Act!(c::Local,action::Action) 
            config = c
            # config = deepcopy(c)
            Act!(config,config.type,action)
        end
        #
        function Act!(c::Local,choice::Choice,action::Action) 
            # old_config = c
            "Search for corresponding Interact in Choice."
            for interact in choice
                act = Act!(c,interact,action)
                "Interact successful?"
                if act.success
                    return act
                end
            end

            "Loop finished and no interact found."
            # new(old_config,false,action,[])
            new(false,action,λ())
        end
        #
        function Act!(c::Local,interact::Interact,action::Action)
            # old_config = c

            "Check if actions match."
            interact_action = Action(interact)
            if interact_action==action
                "Resets of interaction."
                resets = interact.resets
                "Check if constraints satisfied."
                if Evaluate!(c.valuations,interact).enabled
                    "Reset Clocks."
                    ResetClocks!(c.valuations,resets)

                    "Update Configuration type."
                    c.type = interact.child
                    
                    "Constraints satisfied, clocks reset, and type progressed."
                    # return new(old_config,true,action,resets)
                    return new(true,action,resets)
                else
                    "Constraints not satisfied, do nothing."
                    # return new(old_config,false,action,resets)
                    return new(false,action,resets)
                end
            end
            "Interaction not able to act."
            new(false,action,λ())
        end
    end

    Base.show(l::Act!,io::Core.IO=stdout) = print(io,string(l))

    function Base.string(l::Act!) 
        if l.success
            string("⟶ $(string(l.label)) [$(string(l.resets)) ↦ 0]")
        else
            string("̸⟶ $(string(l.label))")
        end
    end

end