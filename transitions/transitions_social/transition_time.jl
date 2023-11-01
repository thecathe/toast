module SocialTransitionTime

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SocialTransition
    import ..Transitions.TransitionLocal!
    import ..Transitions.TransitionSocial!
    import ..Transitions.Tick!
    import ..Transitions.Recv!

    export Time!

    struct Time! <: SocialTransition
        success::Bool
        time::TimeStep!

        ""
        function Time!(c::Social,t::Real)
            "Make Local Configuration."
            localised = Local(c)

            "Make Configuration with proposed delay."
            delayed_copy = deepcopy(localised)
            TimeStep!(ddelayed_copy.valuations,t)

            "Check the (urgency) premise."
            urgency_copy = deepcopy(localised)
            urgency_init = TransitionSocial!(urgency_copy,:recv)

            @assert urgency_init.transition isa Recv! "Time! (urgency), unexpected initial case: $(typeof(urgency_init.transition))."
            # is [recv] possible? then time not
            if urgency_init.success
                return new(false,t)
            else
                # if not success and !(action isa nothing), then check if future enabled
                if urgency_init.transition.action isa Nothing
                    # this is bad, but technically passes (urgency)
                    @warn "Time! (urgency), action returned was Nothing, head of Queue may be unspecified."
                else
                    # get relevant interaction and get its constraints
                    queue_head = head!(localised.queue)
                    relevant_interact = nothing
                    for i in (localised.type isa Choice ? localised.type : Choice([localised.type]))
                        # match?
                        if Action(i)==Action(:recv,queue_head)
                            relevant_interact = i
                            break
                        end
                    end
                    @assert relevant_interact isa Interact "Time! (urgency), should have found single Interact, not: $(typeof(relevant_interact))."
                    constraints = relevant_interact.constraints
                end
            end


            "Check the (persistency) premise."


            "Elevate to Tick!"
            transition = TransitionLocal!(localised,:t,t)
            
            act = transition.transition

            @assert act isa Tick! "Time!, act was unexpected type ($(typeof(act)))."

            "Bring back changes to Social Configuration."
            c.valuations = localised.valuations

            new(true, act.time)

        end

    end

end