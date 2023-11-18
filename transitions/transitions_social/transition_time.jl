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

        "Check premises of [time], then elevate to [tick]"
        function Time!(c::Social,t::Num)

            
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
            if localised_evaluate.future_en === nothing
                # must be End, μ, α
                met_premise_persistency = true
            elseif localised_evaluate.future_en
                # @info "[time] c is fe\n$(string(localised_evaluate,:full,:expand))."
                localised_delayed_evaluate = Evaluate!(localised_delayed)
                if localised_delayed_evaluate.future_en
                    met_premise_persistency = true
                    # @info "[time] (delayed) c is fe\n$(string(localised_delayed_evaluate,:full,:expand))."
                else
                    @warn "[time] (delayed) not fe...\n$(string(localised_delayed_evaluate,:full,:expand))."
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
                    relevant_constraints = relevant_interact.constraints
                    relevant_clocks = relevant_constraints.clocks
                    # make sure all relevant clocks are init
                    for x in relevant_clocks
                        init!(x, localised.valuations)
                        init!(x, localised_delayed.valuations)
                    end
                    # 
                    before_clocks = Array{Clock}([x for x in localised.valuations.clocks if x.label ∈ relevant_clocks])
                    after_clocks = Array{Clock}([x for x in localised_delayed.valuations.clocks if x.label ∈ relevant_clocks])

                    intersections = Array{Bool}([])

                    for x in relevant_clocks
                        before_clock = nothing
                        for y in before_clocks
                            if y.label == x
                                before_clock = y
                                break
                            end
                        end
                        @assert before_clock isa Clock "[time] (urgency) before_clock \"$(x)\" is expected to be a Clock, not $(typeof(before_clock))...:\n$(string(before_clocks))"
                        
                        after_clock = nothing
                        for y in after_clocks
                            if y.label == x
                                after_clock = y
                                break
                            end
                        end
                        @assert after_clock isa Clock "[time] (urgency) after_clock \"$(x)\" is expected to be a Clock, not $(typeof(after_clock))...:\n$(string(after_clocks))"
                        

                        # get upper and lower bounds for each clock given the relevant constraint
                        # TODO without using flattened
                        # flattened = δ(:flatten, relevant_constraints)
                        # flat = Array{δ}([flattened.args...])
                        bounds = boundsOf(x,relevant_constraints)
                        # check if clock lb or ub falls inbetween ANY pair of bounds
                        for b in bounds
                            clock_lb = before_clock.value
                            clock_ub = after_clock.value
                            lb = b[1]
                            ub = b[2]
                            if ub isa Bool
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_ub) = ($(lb) < $(clock_ub))."
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_lb) = ($(lb) < $(clock_lb))."
                                
                                push!(intersections, (lb < clock_ub))
                                push!(intersections, (lb < clock_lb))
                            else
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_ub && clock_ub < ub) = ($(lb) < $(clock_ub) && $(clock_ub) < $(ub))."
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_lb && clock_lb < ub) = ($(lb) < $(clock_lb) && $(clock_lb) < $(ub))."
                                
                                push!(intersections, (lb < clock_ub && clock_ub < ub))
                                push!(intersections, (lb < clock_lb && clock_lb < ub))
                            end
                        end

                    end

                    met_premise_urgency = !(true ∈ intersections)
                end
            end


            met_premise = Array{Bool}([met_premise_configuration,met_premise_persistency,met_premise_urgency])
            # @info "[time] $(string(met_premise))."
            success = false ∉ met_premise

            # move clocks if success
            if success
                c.valuations = localised_delayed.valuations
            else
                @info "[time] (configuration: $(string(met_premise[1]))) (persistency: $(string(met_premise[2]))) (urgency: $(string(met_premise[3])))."
            end

            new(success, met_premise, unfolded, unfolded_str)
        end

    end

end