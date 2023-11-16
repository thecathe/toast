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
                label = "[wait] ($(label))"


            # elseif kind==:tau
            #     @assert length(args)==0 "(System) Transition ($(string(kind))) expects 0 arguments, got: [$(string(args))] ($(length(args)))."

            #     # make transition
            #     transition = Recv!(c)
            #     action = transition.action

            #     success = transition.success
            #     label = "$(label)[recv] $(string(action)) [$(string(transition.resets)) ↦ 0]"

            else
                label = "ERROR"
                success = false
                @warn "(System) Transition, unhandled kind: $(string(kind))."
            end

            new(origin,keep,label,success,kind,transition)

        end
    end

end