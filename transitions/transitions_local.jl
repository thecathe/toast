module TransitionsLocal
    
    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.Transition
    import ..Transitions.transition_labels

    import ..Transitions.Tick!
    import ..Transitions.Act!
    import ..Transitions.Unfold!

    export TransitionLocal!

    struct TransitionLocal!
        origin::T where {T<:Union{Nothing,R} where {R<:Configuration}}
        has_origin::Bool

        label::String
        success::Bool
        kind::Symbol

        transition::Q where {Q<:LocalTransition}

        unfolded::Bool
        unfolded_str::String

        TransitionLocal!(c::Local,a::Action,args...; keep::Bool = false) = TransitionLocal!(c,a.direction.dir,a.msg,args...;keep)
        
        function TransitionLocal!(c::Local,kind::Symbol,args...; keep::Bool = false)

            @assert kind ∈ transition_labels "TransitionLocal! kind ($(string(kind))) is not supported."

            origin = keep ? c : nothing
            label = ""

            "TransitionLocal!, if recursion, then unfold first."
            if c.type isa μ
                unfold = Unfold!(c)
                unfolded = true
                unfolded_str = "[unfold] $(string(unfold)) ⟶ "
                label = "$(label)$(unfolded_str)"
            else
                unfolded = false
                unfolded_str = ""
            end

            "Select Transition from kind."
            if kind==:t
                @assert length(args)==1 "TransitionLocal! ($(string(kind))) expects 1 argument: time value."
                time_value = args[1]
                @assert time_value isa Num "(Local) Transition ($(string(kind))) expects a Number, not $(typeof(time_value))."
                @assert time_value >= 0 "(Local) Transition ($(string(kind))) expects a Positive Number, not $(string(time_value))."
                label = "$(label)[tick] t($(time_value))"

                # make transition
                transition = Tick!(c,time_value)
                success = true

            elseif kind ∈ [:send,:recv]
                @assert length(args)==1 "TransitionLocal! ($(string(kind))) expects 1 argument: message(label,payload)."
                message = args[1]
                action = Action(kind,message)

                # make transition
                transition = Act!(c,action)

                success = transition.success
                label = "$(label)[act] $(string(action)) [$(string(transition.resets)) ↦ 0]"

            else
                label = "$(label)ERROR"
                success = false
                @warn "TransitionLocal! unhandled kind: $(string(kind))."
            end

            new(origin,keep,label,success,kind,transition,unfolded,unfolded_str)

        end
    end

end