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
                is_expected = false
                relevant_interact = nothing
                # @debug "[time] (urgency), $(string(localised_evaluate,:full,:expand))."
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

                    # TODO
                    # check :deq,:dgeq => must be false
                    # diag_constraints = Array{}

                    bounds = δBounds(relevant_constraints;normalise=true)

                    # @info "[time], bounds: $(string(bounds))."
                    @debug "[time], bounds: $(string(bounds))."



                    # for x in b
                    for x in bounds.clocks
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
                        # check if clock lb or ub falls inbetween ANY pair of bounds
                        # for x in bounds.clocks
                        clock_intersections = Array{Bool}([])
                        clock_lb = before_clock.value
                        clock_ub = after_clock.value
                        for b in bounds.bounds[x]
                            lb = b[1]
                            ub = b[2]
                            if ub isa Bool
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_ub) = ($(lb) < $(clock_ub))."
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_lb) = ($(lb) < $(clock_lb))."
                                
                                push!(clock_intersections, (lb < clock_ub))
                                push!(clock_intersections, (lb < clock_lb))
                            else
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_ub && clock_ub < ub) = ($(lb) < $(clock_ub) && $(clock_ub) < $(ub))."
                                @debug "[time] (urgency), bounds($(x)): $(lb < clock_lb && clock_lb < ub) = ($(lb) < $(clock_lb) && $(clock_lb) < $(ub))."
                                
                                push!(clock_intersections, (lb < clock_ub && clock_ub < ub))
                                push!(clock_intersections, (lb < clock_lb && clock_lb < ub))
                            end
                        end

                        # if looks viable, check harsher constraints
                        if !(true ∈ intersections)
                            clocks_to_check = [clock_lb,clock_ub]
                            before_region = nothing
                            after_region = nothing
                            for c_index in range(1,length(clocks_to_check))
                                _clock = clocks_to_check[c_index]
                                # check if "jumped over" viable zone  
                                for b_lb_index in range(1,length(bounds.bounds[x]))
                                    b_lb_lb = bounds.bounds[x][b_lb_index][1]
                                    b_lb_ub = bounds.bounds[x][b_lb_index][2]

                                    # skip true
                                    if b_lb_ub isa Bool
                                        @assert b_lb_ub==true "[time] (urgency), b_lb_ub isa Bool but not true: $(string(b_lb_ub))."
                                        continue
                                    end

                                    # check if clock is greater than the ub
                                    if _clock > b_lb_ub
                                        # find the closest range that is after this
                                        b_ub_lb = nothing
                                        for b_ub_index in range(1,length(bounds.bounds[x]))
                                            # skip the same one                                    
                                            if b_lb_index==b_ub_index
                                                continue
                                            end
                                            
                                            cur_b_ub_lb = bounds.bounds[x][b_ub_index][1]
                                            cur_b_ub_ub = bounds.bounds[x][b_ub_index][2]

                                            # must be later than b_lb
                                            if cur_b_ub_lb > b_lb_ub && (b_ub_lb===nothing || b_ub_lb > cur_b_ub_lb)
                                                # @info "[time] (urgency), "
                                                b_ub_lb = cur_b_ub_lb
                                                @debug "[time] (urgency), new lb/ub: ($(string(b_lb_ub)), $(string(b_ub_lb)))."
                                            end
                                        end

                                        # if no ub found, use this region
                                        if b_ub_lb===nothing
                                            if c_index==1
                                                before_region = (b_lb_ub,true)
                                            else
                                                after_region = (b_lb_ub,true)
                                            end
                                        else
                                            # if clock falls between intermediate lb and ub
                                            if _clock < b_ub_lb
                                                if c_index==1
                                                    before_region = (b_lb_ub,b_ub_lb)
                                                else
                                                    after_region = (b_lb_ub,b_ub_lb)
                                                end
                                                break
                                            end
                                        end
                                    end
                                end

                            end

                            
                            @assert before_region!==nothing "[time] (urgency), before_region cannot be nothing."
                            @debug "[time] (urgency), before_region: ($(before_region[1]), $(before_region[2]))."

                            @assert after_region!==nothing "[time] (urgency), after_region cannot be nothing."
                            @debug "[time] (urgency), after_region: ($(after_region[1]), $(after_region[2]))."

                            jumped_over_enabled_region = !(before_region[1]==after_region[1] && before_region[2]==after_region[2])
                            met_premise_urgency_jump = jumped_over_enabled_region

                            push!(clock_intersections,jumped_over_enabled_region)

                        end


                        push!(intersections, clock_intersections...)

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
                if met_premise_urgency_jump
                    @warn "[time] (urgency): it looks like you attempted to jump over a whole period where you could receive from the queue."
                end
            end

            new(success, met_premise, unfolded, unfolded_str)
        end

    end

end