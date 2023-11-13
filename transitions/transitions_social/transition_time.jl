module SocialTransitionTime

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SocialTransition
    import ..Transitions.TransitionLocal!
    import ..Transitions.Act!

    export Time!

    struct Time! <: SocialTransition
        success::Bool
        met_premise::Array{Bool}
        # 1 - (configuration)
        # 2 - (persistency)
        # 3 - (urgency)

        
        unfolded::Bool
        unfolded_str::String

        Time!(c::Social,t::Num) = Time!(c,UInt8(t))
        
        "Pop! head of Queue, then elevate to Act!"
        function Time!(c::Social,t::UInt8)

            
            # 
            # ~ (configuration) premise
            #
            "Make Local Configuration, then elevate to Tick!."
            localised = Local(c)
            localised_delayed = deepcopy(localised)
            transition = TransitionLocal!(localised_delayed,:t,t)
            unfolded = transition.unfolded
            unfolded_str = transition.unfolded_str

            met_premise_configuration = true

            #
            # ~ (persistency) premise
            #
            "Evaluate! Local Configuration, if FE, delayed Evaluate! must be FE."
            localised_evaluate = Evaluate!(localised)
            if localised_evaluate.future_en
                localised_delayed_evaluate = Evaluate!(localised_delayed)
                if localised_delayed_evaluate.future_en
                    met_premise_persistency = true
                else
                    met_premise_persistency = false
                end
            else
                met_premise_persistency = true
            end

            #
            # ~ (urgency) premise
            #
            """ rule [time] (urgency) premise
            ∀ t' < t : (ν+t', S, M)⟶̸ τ
            ---
            if,
                - the queue is non-empty
                - the message corresponds to some future-enabled action
                - the constraints of the action intersect with the valuation of clocks between now and the time step
            then, this condition is NOT met.
            """
            if isempty(c.queue)
                met_premise_urgency = true
            else
                msg = head!(c.queue; pop=false)[1]
                # check against all future-enabled actions, find if match
                # is_expected = true ∈ [msg == act.msg for act in localised_evaluate.actions_fe]
                is_expected = false
                relevant_interact = nothing
                for i in localised_evaluate.interact_fe
                    # if found relevant interact with matching message, note and break
                    if i.msg == msg
                        is_expected = true
                        relevant_interact = i
                        break
                    end
                end
                # if is_expected == false
                if relevant_interact === nothing
                # if relevant_interact === nothing && is_expected == false
                    @info "[time] (urgency), no corresponding action found for message ($(string(msg))) in:\n$(string(c.type,:full))"
                    met_premise_urgency = true
                else
                    # corresponding action found, check if they intersect with the relevant clocks
                    relevant_clocks = relevant_interact.constraints.clocks
                    # make sure all relevant clocks are init
                    for x in relevant_clocks
                        init!(x, localised.valuations)
                        init!(x, localised_delayed.valuations)
                    end
                    # 
                    before_clocks = Array{Clock}([x for x in localised.valuations.clocks if x.label ∈ relevant_clocks])
                    after_clocks = Array{Clock}([x for x in localised_delayed.valuations.clocks if x.label ∈ relevant_clocks])
                    # before_clocks = filter(x -> x.label ∈ relevant_clocks, localised.valuations.clocks)
                    # after_clocks = filter(x -> x.label ∈ relevant_clocks, localised_delayed.valuations.clocks)
                    
                    # @assert forall(x -> x in after_clocks, before_clocks) "[time] (urgency), the before and after clocks have different contents:\nbefore: $(string(before_clocks))\nafter: $(string(after_clocks))"

                    # create set of constraints for the possible valuation of each clock
                    list_of_clock_constraints = Array{δ}([relevant_interact.constraints])
                    for x in relevant_clocks
                        before_clock = nothing
                        for y in before_clocks
                            if y.label == x
                                before_clock = y
                                break
                            end
                        end
                        # before_clock = findfirst(y -> x == y.label, before_clocks)
                        # @assert !(before_clock isa Nothing) "[time] (urgency), before_clock \"$(x)\" returned nothing:\n$(string(before_clocks))"
                        @assert before_clock isa Clock "[time] (urgency) before_clock \"$(x)\" is expected to be a Clock, not $(typeof(before_clock))...:\n$(string(before_clocks))"
                        
                        # after_clock = findfirst(y -> x == y.label, after_clocks)
                        after_clock = nothing
                        for y in after_clocks
                            if y.label == x
                                after_clock = y
                                break
                            end
                        end
                        # @assert !(after_clock isa Nothing) "[time] (urgency), after_clock \"$(x)\" returned nothing:\n$(string(after_clocks))"
                        @assert after_clock isa Clock "[time] (urgency) after_clock \"$(x)\" is expected to be a Clock, not $(typeof(after_clock))...:\n$(string(after_clocks))"
                        
                        push!(list_of_clock_constraints, δ(:and, 
                                δ(:geq, before_clock.label, before_clock.value), 
                                δ(:not, δ(:geq, after_clock.label, after_clock.value)) 
                                # δ(:not, δ(:and, 
                                #     δ(:not, δ(:eq, after_clock.label, after_clock.value)), 
                                #     δ(:geq, after_clock.label, after_clock.value)
                                # )) 
                            ))
                    end
                    # make single δ
                    clock_constraints = δ(:conjunct, list_of_clock_constraints...)
                    # evaluate (use current valuations to ensure urgency)
                    conjunct_eval = δEvaluation!(localised.valuations,clock_constraints)
                    eval_result = eval(conjunct_eval.expr)
                    @info "[time] (urgency), evaluation: $(string(eval_result)) =\n$(string(conjunct_eval.expr))\n$(string(clock_constraints))."
                    # condition met if eval yields false, as constraints do not overlap
                    met_premise_urgency = string(eval_result)=="false"
                end
            end


            met_premise = Array{Bool}([met_premise_configuration,met_premise_persistency,met_premise_urgency])
            @info "[time] $(string(met_premise))."
            success = false ∉ met_premise

            # move clocks if success
            if success
                c.valuations = localised_delayed.valuations
            end

            new(success, met_premise, unfolded, unfolded_str)
        end

    end

end