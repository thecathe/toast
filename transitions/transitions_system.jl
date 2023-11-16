module TransitionsSystem

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.Transition
    import ..Transitions.transition_labels

    import ..Transitions.Wait!
    import ..Transitions.Par!
    import ..Transitions.Com!

    export TransitionSystem!

    struct TransitionSystem!

        origin::T where {T<:Union{Nothing,R} where {R<:Configuration}}
        has_origin::Bool
        label::String
        success::Bool
        lhs_success::Bool
        rhs_success::Bool
        kind::Symbol
        transition::Q where {Q<:Transition}

        function TransitionSystem!(c::System,kind::Symbol,args...; keep::Bool = false)

            @assert kind ∈ transition_labels "(System) Transition kind ($(string(kind))) is not supported."

            origin = keep ? c : nothing
            label = ""
            
            "Select (System) Transition from kind."
            if kind==:t
                @assert length(args)==1 "(System) Transition ($(string(kind))) expects 1 argument: time value."
                time_value = args[1]
                @assert time_value isa Num "(System) Transition ($(string(kind))) expects a Number, not $(typeof(time_value))."
                @assert time_value >= 0 "(System) Transition ($(string(kind))) expects a Positive Number, not $(string(time_value))."
                label = "t=$(time_value)"

                # make transition
                transition = Wait!(c,time_value)
                success = transition.success
                lhs_success = transition.lhs_success
                rhs_success = transition.rhs_success
                label = "[wait] ($(label))"


            elseif kind==:tau
                # either [com] or [par] are possible here

                # check if message for com
                if length(args)>0
                    @assert length(args)==1 "(System) Transition ($(string(kind))) only expects one additional args, got $(length(args)): $(string(join(args,", ")))."
                    @assert args[1] isa Msg "(System) Transition ($(string(kind))) expects a Msg, not $(typeof(args[1])): $(string(args[1]))."

                    transition = Com!(c, args[1])
                    success = transition.success
                    lhs_success = transition.lhs_success
                    rhs_success = transition.rhs_success

                    lhs_taken = transition.lhs_taken
                    rhs_taken = transition.rhs_taken

                    "Check if unfolding occured."
                    if transition.lhs_unfolded
                        label = "$(label)(l)$(transition.lhs_unfolded_str)"
                    end
                    if transition.rhs_unfolded
                        label = "$(label)(r)$(transition.rhs_unfolded_str)"
                    end


                    if lhs_taken && rhs_taken
                        label = "$(label)[com-x]"
                    elseif lhs_taken
                        label = "$(label)[com-l]"
                    elseif rhs_taken
                        label = "$(label)[com-r]"
                    else
                        label = "$(label)[com]"
                    end

                else
                    # must be par

                    transition = Par!(c)
                    success = transition.success
                    lhs_success = transition.lhs_success
                    rhs_success = transition.rhs_success

                    "Check if unfolding occured."
                    if transition.lhs_unfolded
                        label = "$(label)(l)$(transition.lhs_unfolded_str)"
                    end
                    if transition.rhs_unfolded
                        label = "$(label)(r)$(transition.rhs_unfolded_str)"
                    end


                    if lhs_success && rhs_success
                        label = "$(label)[par-x]"
                    elseif lhs_success
                        label = "$(label)[par-l]"
                    elseif rhs_success
                        label = "$(label)[par-r]"
                    else
                        label = "$(label)[par]"
                    end

                end

            else
                label = "ERROR"
                success = false
                lhs_success = false
                rhs_success = false
                @warn "(System) Transition, unhandled kind: $(string(kind))."
            end

            new(origin,keep,label,success,lhs_success,rhs_success,kind,transition)

        end
    end


end