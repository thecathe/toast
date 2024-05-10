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

        """
            Time!(c, t)

        Makes a transition via [time] if each of the premises (configuration, persistency, urgency) are adhered to.

        If each premise is a success, then the transition is elevated to [tick].

        # Premises of [time]
        ## Configuration
        Simply elevates to [tick].

        ## Persistency
        If the configruation is future-enabled prior to the delay, then it should still be future-enabled after the delay.

        ## Urgency
            ∀ t' < t : (ν+t', S, M)⟶̸ τ (via [recv])
        Checks that no message can be received from the queue at a point earlier than the delay.
        ### Methodology
        - If the queue is empty, this holds.
        - If the queue is non-empty:
            - Does the message in the queue correspond to some future-enabled action? If yes, continue. Else, this holds (as it cannot apply).
            - For each clock, generate each bounded-region where its constraints are satisfied. Then:
                - First check: are either the starting or ending valuation within one of these regions? If yes, this premise fails.
                - Second check: generate the *intermediate* regions that encompass the starting and ending valuations of clocks. If these are not the same, then the time delay has jumped over a region where receiving was viable; this premise fails.

        # Arguments
        - `c::Social`: the social configuration transitioning via [time].
        - `t::Num`: the amount of time to step.
        """
        function Time!(c::Social,t::Num)

            met_premise_configuration = false
            met_premise_persistency = false
            met_premise_urgency = false
            met_premise_urgency_jump = false
            
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
                @debug "[time] c is fe\n$(string(localised_evaluate,:full,:expand))."
                localised_delayed_evaluate = Evaluate!(localised_delayed)
                if localised_delayed_evaluate.future_en
                    met_premise_persistency = true
                    @debug "[time] (delayed) c is fe\n$(string(localised_delayed_evaluate,:full,:expand))."
                else
                    # TODO CHECK THIS EXAMPLE D
                    # @warn "[time] (delayed) not fe...\n$(string(localised_delayed_evaluate,:full,:expand))."
                    met_premise_persistency = false
                end
            else
                met_premise_persistency = true
            end

            #
            # ~ (urgency) premise
            #
            if isempty(c.queue)
                met_premise_urgency = true
            else
                msg = head!(c.queue; pop=false)[1]
                # check against all future-enabled actions, find if match
                relevant_interact = nothing
                # @debug "[time] (urgency), $(string(localised_evaluate,:full,:expand))."
                for i in localised_evaluate.interact_fe
                    # if found relevant interact with matching message, note and break
                    if i.msg == msg
                        relevant_interact = i
                        break
                    end
                end
                if relevant_interact === nothing
                    @warn "[time] (urgency), no future-enabled action found for message ($(string(msg))) in:\n$(string(c.type,:full))"
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

                    bounds = δBounds(relevant_constraints;normalise=true)

                    # @info "[time], bounds: $(string(bounds))."
                    @debug "[time], bounds: $(string(bounds))."

                    # for each clock relevant to this constraint
                    # check after_clock is greater than lb (if this is true for all clocks and their relative constraints, then we must check that this is the lowest possible time step)
                    passes_lb_check = Array{Bool}([])
                    for x in bounds.clocks
                        @debug "[time] (urgency), clock: $(string(x))."

                        # before_clock = nothing
                        # for y in before_clocks
                        #     if y.label == x
                        #         before_clock = y
                        #         break
                        #     end
                        # end
                        # @assert before_clock isa Clock "[time] (urgency) before_clock \"$(x)\" is expected to be a Clock, not $(typeof(before_clock))...:\n$(string(before_clocks))"


                        # get the value of the clock after time step
                        after_clock = nothing
                        for y in after_clocks
                            if y.label == x
                                after_clock = y
                                break
                            end
                        end
                        @assert after_clock isa Clock "[time] (urgency) after_clock \"$(x)\" is expected to be a Clock, not $(typeof(after_clock))...:\n$(string(after_clocks))"
                        
                        # check after_clock is greater than lb (if this is true for all clocks and their relative constraints, then we must check that this is the lowest possible time step)
                        for b in bounds.bounds[x]
                            lb = b[1]
                            @debug "[time] (urgency, lb <= after_clock.value) $(string(lb)) <= $(string(after_clock.value)) = $(string(lb <= after_clock.value))"
                            if lb <= after_clock.value
                                push!(passes_lb_check,true)
                            else
                                push!(passes_lb_check,false)
                            end
                        end
                    end

                    if !false∈passes_lb_check
                        # check that at least one of the relevant clocks is equal to the respective lb
                        is_lb = Array{Bool}([])
                        for x in bounds.clocks
                            # get the value of the clock after time step
                            after_clock = nothing
                            for y in after_clocks
                                if y.label == x
                                    after_clock = y
                                    break
                                end
                            end
                            @assert after_clock isa Clock "[time] (urgency) after_clock \"$(x)\" is expected to be a Clock, not $(typeof(after_clock))...:\n$(string(after_clocks))"
                        
                            clock_is_lb = Array{Bool}([])
                            for b in bounds.bounds[x]
                                lb=b[1]
                                if lb==after_clock.value
                                    @debug "[time] (urgency, lb == after_clock.value) after_clock $(string(x)) $(string(lb)) == $(string(after_clock.value)) = $(string(lb == after_clock.value))"
                                    push!(clock_is_lb,true)
                                else
                                    @debug "[time] (urgency, lb == after_clock.value) after_clock $(string(x)) NOT $(string(lb)) == $(string(after_clock.value)) = $(string(lb == after_clock.value))"
                                    push!(clock_is_lb,false)
                                end
                            end
                            @debug "[time] (urgency) after_clock $(string(x)) is lb ?= $(string(true∈clock_is_lb))"
                            push!(is_lb,true∈clock_is_lb)
                        end
                        if true∈is_lb
                            met_premise_urgency=true
                        else
                            # fail if none of the clocks are lb
                            met_premise_urgency=false
                        end
                    else
                        # automatically pass if not even enabling recv
                        met_premise_urgency=true
                    end


                    #     # get upper and lower bounds for each clock given the relevant constraint
                    #     # TODO without using flattened
                    #     # flattened = δ(:flatten, relevant_constraints)
                    #     # flat = Array{δ}([flattened.args...])
                    #     # check if clock lb or ub falls inbetween ANY pair of bounds
                    #     # for x in bounds.clocks
                    #     clock_intersections = Array{Bool}([])
                    #     clock_lb = before_clock.value
                    #     clock_ub = after_clock.value
                    #     for b in bounds.bounds[x]
                    #         lb = b[1]
                    #         ub = b[2]
                    #         if ub isa Bool
                    #             @debug "[time] (urgency), * bounds($(x)): $(lb < clock_ub) = ($(lb) < $(clock_ub))."
                    #             @debug "[time] (urgency), * bounds($(x)): $(lb < clock_lb) = ($(lb) < $(clock_lb))."
                                
                    #             push!(clock_intersections, (lb < clock_ub))
                    #             push!(clock_intersections, (lb < clock_lb))
                    #         else

                    #             @debug "[time] (urgency), bounds($(x)): $(lb < clock_ub && clock_ub < ub) = ($(lb) < $(clock_ub) && $(clock_ub) < $(ub))."
                    #             @debug "[time] (urgency), bounds($(x)): $(lb < clock_lb && clock_lb < ub) = ($(lb) < $(clock_lb) && $(clock_lb) < $(ub))."
                                
                    #             push!(clock_intersections, (lb < clock_ub && clock_ub < ub))
                    #             push!(clock_intersections, (lb < clock_lb && clock_lb < ub))
                    #         end
                    #     end
                    #     @debug "[time] (urgency), clock $(string(x)) intersections: $(string(clock_intersections))"
                    #     push!(intersections, clock_intersections...)

                    #     # if looks viable, check harsher constraints
                    #     if !(true ∈ intersections)
                    #         clocks_to_check = [clock_lb,clock_ub]
                    #         before_region = nothing
                    #         after_region = nothing
                    #         for c_index in range(1,length(clocks_to_check))
                    #             if c_index==1
                    #                 @debug "[time] (urgency), before region..."
                    #             else
                    #                 @debug "[time] (urgency), after region..."
                    #             end
                    #             _clock = clocks_to_check[c_index]
                    #             # check if "jumped over" viable zone  
                    #             for b_lb_index in range(1,length(bounds.bounds[x]))
                    #                 b_lb_lb = bounds.bounds[x][b_lb_index][1]
                    #                 b_lb_ub = bounds.bounds[x][b_lb_index][2]

                    #                 # skip true
                    #                 if b_lb_ub isa Bool
                    #                     @assert b_lb_ub==true "[time] (urgency), b_lb_ub isa Bool but not true: $(string(b_lb_ub))."
                    #                     continue
                    #                 end

                    #                 # check if clock is greater than the ub
                    #                 if _clock > b_lb_ub
                    #                     # find the closest range that is after this
                    #                     b_ub_lb = nothing
                    #                     for b_ub_index in range(1,length(bounds.bounds[x]))
                    #                         # skip the same one                                    
                    #                         if b_lb_index==b_ub_index
                    #                             continue
                    #                         end
                                            
                    #                         cur_b_ub_lb = bounds.bounds[x][b_ub_index][1]
                    #                         cur_b_ub_ub = bounds.bounds[x][b_ub_index][2]

                    #                         # must be later than b_lb
                    #                         if cur_b_ub_lb > b_lb_ub && (b_ub_lb===nothing || b_ub_lb > cur_b_ub_lb)
                    #                             # @info "[time] (urgency), "
                    #                             b_ub_lb = cur_b_ub_lb
                    #                             @debug "[time] (urgency), new lb/ub: ($(string(b_lb_ub)), $(string(b_ub_lb)))."
                    #                         end
                    #                     end

                    #                     # if no ub found, use this region
                    #                     if b_ub_lb===nothing
                    #                         if c_index==1
                    #                             before_region = (b_lb_ub,true)
                    #                         else
                    #                             after_region = (b_lb_ub,true)
                    #                         end
                    #                     else
                    #                         # if clock falls between intermediate lb and ub
                    #                         if _clock < b_ub_lb
                    #                             if c_index==1
                    #                                 before_region = (b_lb_ub,b_ub_lb)
                    #                             else
                    #                                 after_region = (b_lb_ub,b_ub_lb)
                    #                             end
                    #                             break
                    #                         else
                    #                             @debug "[time] (urgency), skipped $(c_index==1 ? "lb" : "ub"): ($(string(b_lb_ub)), $(string(b_ub_lb)))."
                    #                         end
                    #                     end
                    #                 end
                    #             end

                    #         end

                    #         if before_region===nothing
                    #             @debug "[time] (urgency), before_region is nothing. Likely within existing region."
                    #         else
                    #             @debug "[time] (urgency), before_region: ($(before_region[1]), $(before_region[2]))."

                    #             if after_region===nothing
                    #                 @debug "[time] (urgency), after_region is nothing. Delay likely yields same intermediate region."
                    #             else
                    #                 @debug "[time] (urgency), after_region: ($(after_region[1]), $(after_region[2]))."

                    #                 jumped_over_enabled_region = !(before_region[1]==after_region[1] && before_region[2]==after_region[2])
                    #                 met_premise_urgency_jump = jumped_over_enabled_region

                    #                 push!(intersections,jumped_over_enabled_region)

                    #             end
                    #         end
                    #     end


                    # end

                    # met_premise_urgency = !(true ∈ intersections)
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
                if met_premise_urgency_jump
                    @warn "[time] (urgency): it looks like you attempted to jump over a whole period where you could receive from the queue."
                end
            end

            new(success, met_premise, unfolded, unfolded_str)
        end

    end

end