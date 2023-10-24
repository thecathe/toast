module Transitions

    import Base.show
    import Base.string

    using ..LogicalClocks
    using ..SessionTypes
    using ..Configurations

    
    include("transitions/transitions_local/transition_tick.jl")
    using .LocalTransitionTick
    export Tick!
    
    include("transitions/transitions_local/transition_act.jl")
    using .LocalTransitionAct
    export Act!

    include("transitions/transitions_local/transition_unfold.jl")
    using .LocalTransitionUnfold
    export Unfold!


    const transition_labels = [:send,:recv,:ell,:tau,:t] 

    export Transition!

    struct Transition!
        "If has_keep, contains the original Configuration, prior to the transition."
        origin::T where {T<:Union{Nothing,R} where {R<:Configuration}}
        "Reflects if the Transition was constructed with keep==true."
        has_origin::Bool
        "The Transition label."
        label::String
        "If the Transition is successful."
        success::Bool
        kind::Symbol

        "Transition for Local Configurations."
        function Transition!(c::Local,kind::Symbol,args...; keep::Bool = false)

            @assert kind ∈ transition_labels "(Local) Transition kind ($(string(kind))) is not supported."

            origin = keep ? c : nothing
            label = ""

            "(Local) Transition, if recursion, then unfold first."
            if c.type isa μ
                Unfold!(c)
                label = "$(label)[unfold] "
            end

            "Select Transition from kind."
            if kind==:t
                @assert length(args)==1 "(Local) Transition ($(string(kind))) expects 1 argument: time value."
                time_value = args[1]
                label = "$(label)[tick] t($(time_value))"

                # make transition
                Tick!(c,time_value)
                success = true

            elseif kind ∈ [:send,:recv]
                @assert length(args)==1 "(Local) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
                message = args[1]
                action = Action(kind,message)

                # make transition
                act = Act!(c,action)

                success = act.success
                label = "$(label)[act] $(string(action)) [$(string(act.resets)) ↦ 0]"

            else
                label = "$(label)ERROR"
                success = false
                @warn "(Local) Transition, unhandled kind: $(string(kind))."
            end

            new(origin,keep,label,success,kind)

        end

        "Transition for Social Configurations."
        function Transition!(c::Social,kind::Symbol,args...; keep::Bool = false)

            @assert kind ∈ transition_labels "(Social) Transition kind ($(string(kind))) is not supported."

            if keep
                origin = c
            else
                origin = nothing
            end

            "Select (Social) Transition from kind."
            if kind==:t
                @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: time value."
                time_value = args[1]
                label = "t=$(time_value)"

                # make transition
                # success = Time!(c,time_value).success

            elseif kind==:send
                @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
                message = args[1]
                action = Action(kind,message)
                label = string(action)

                # make transition
                # success = Send!(c,action).success
                
            elseif kind==:recv
                @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
                message = args[1]
                action = Action(kind,message)
                label = string(action)

                # make transition
                # success = Que!(c,action).success

            elseif kind==:tau
                @assert length(args)==0 "(Social) Transition ($(string(kind))) expects 0 arguments, got: $(string(args))."

                # make transition
                # success = Recv!(c).success

            else
                label = "ERROR"
                success = false
                @warn "(Social) Transition, unhandled kind: $(string(kind))."
            end

            new(origin,keepOrigin,label,success,kind)

        end

    end
    
    Base.show(t::Transition!,io::Core.IO = stdout) = print(io, string(t))

    Base.string(t::Transition!, args...) = string("↪$(t.label) $(t.success ? "⟶" : "̸⟶")")

end