module TransitionsSocial
    
    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.Transition
    import ..Transitions.transition_labels

    import ..Transitions.Time!
    import ..Transitions.Send!
    import ..Transitions.Recv!
    import ..Transitions.Que!

    export TransitionSocial!

    struct TransitionSocial!
        origin::T where {T<:Union{Nothing,R} where {R<:Configuration}}
        has_origin::Bool
        label::String
        success::Bool
        kind::Symbol
        transition::Q where {Q<:Transition}

        function TransitionSocial!(c::Social,kind::Symbol,args...; keep::Bool = false)

            @assert kind ∈ transition_labels "(Social) Transition kind ($(string(kind))) is not supported."

            origin = keep ? c : nothing
            label = ""
            
            "Select (Social) Transition from kind."
            if kind==:t
                @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: time value."
                time_value = args[1]
                label = "t=$(time_value)"

                # make transition
                transition = Time!(c,time_value)
                success = transition.success
                label = "[time] ($(label))"

            elseif kind==:send
                @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
                message = args[1]
                action = Action(kind,message)

                # make transition
                transition = Send!(c,action)

                "Check if unfolding occured."
                if transition.unfolded
                    label = "$(label)$(transition.unfolded_str)"
                end

                success = transition.success
                label = "$(label)[send] $(string(action)) [$(string(transition.resets)) ↦ 0]"
                
            elseif kind==:recv
                @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
                message = args[1]
                action = Action(kind,message)

                # make transition
                transition = Que!(c,action)

                success = transition.success
                label = "$(label)[que] $(string(action))"


            elseif kind==:tau
                @assert length(args)==0 "(Social) Transition ($(string(kind))) expects 0 arguments, got: [$(string(args))] ($(length(args)))."

                # make transition
                transition = Recv!(c)
                action = transition.action

                success = transition.success
                label = "$(label)[recv] $(string(action)) [$(string(transition.resets)) ↦ 0]"

            else
                label = "ERROR"
                success = false
                @warn "(Social) Transition, unhandled kind: $(string(kind))."
            end

            new(origin,keep,label,success,kind,transition)

        end
    end

end