module Transitions

    import Base.show
    import Base.string

    using ..LogicalClocks
    using ..SessionTypes
    using ..Configurations

    export Transition, LocalTransition, SocialTransition, SystemTransition

    abstract type Transition end
    abstract type LocalTransition <: Transition end
    abstract type SocialTransition <: Transition end
    abstract type SystemTransition <: Transition end

    const transition_labels = [:send,:recv,:ell,:tau,:t] 

    export Transition!, TransitionSocial!, TransitionSystem!


    #
    # local transitions
    #
    include("transitions/transitions_local/transition_tick.jl")
    using .LocalTransitionTick
    export Tick!
    
    include("transitions/transitions_local/transition_act.jl")
    using .LocalTransitionAct
    export Act!

    include("transitions/transitions_local/transition_unfold.jl")
    using .LocalTransitionUnfold
    export Unfold!

    include("transitions/transitions_local.jl")
    using .TransitionsLocal
    export TransitionsLocal!
    

    #
    # social transitions
    #
    include("transitions/transitions_social/transition_que.jl")
    using .SocialTransitionQue
    export Que!
    
    include("transitions/transitions_social/transition_send.jl")
    using .SocialTransitionSend
    export Send!
    
    include("transitions/transitions_social/transition_recv.jl")
    using .SocialTransitionRecv
    export Recv!
    
    include("transitions/transitions_social/transition_time.jl")
    using .SocialTransitionTime
    export Time!

    include("transitions/transitions_social.jl")
    using .TransitionsSocial
    export TransitionsSocial!
    


    #
    # system transitions
    #
    include("transitions/transitions_system/transition_wait.jl")
    using .SystemTransitionWait
    export Wait!

    include("transitions/transitions_system/transition_com.jl")
    using .SystemTransitionCom
    # export ComL!, ComR!

    include("transitions/transitions_system/transition_par.jl")
    using .SystemTransitionPar
    # export ParL!, ParR!

    include("transitions/transitions_system.jl")
    using .TransitionsSystem
    export TransitionsSystem!
    
    #
    # handles all transitions
    #
    struct Transition!
        "If has_keep, contains the original Configuration, prior to the transition."
        origin::T where {T<:Union{Nothing,R} where {R<:Configuration}}
        "Reflects if the Transition was constructed with keep==true."
        has_origin::Bool
        "The Transition label."
        label::String
        "If the Transition is successful."
        success::Bool
        "Original kind::Symbol transition was called with."
        kind::Symbol
        "Actual Transition made."
        transition::Q where {Q<:Transition}

        "Handle Actions."
        Transition!(c::Local,a::Action,args...; keep::Bool = false) = TransitionLocal!(c,a.direction.dir,a.msg,args...;keep)

        "Transition for Local Configurations."
        Transition!(c::Local,kind::Symbol,args...; keep::Bool = false) = TransitionLocal!(c,kind,args...;keep)
        # function Transition!(c::Local,kind::Symbol,args...; keep::Bool = false)

        #     @assert kind ∈ transition_labels "(Local) Transition kind ($(string(kind))) is not supported."

        #     origin = keep ? c : nothing
        #     label = ""

        #     "(Local) Transition, if recursion, then unfold first."
        #     if c.type isa μ
        #         Unfold!(c)
        #         label = "$(label)[unfold] "
        #     end

        #     "Select Transition from kind."
        #     if kind==:t
        #         @assert length(args)==1 "(Local) Transition ($(string(kind))) expects 1 argument: time value."
        #         time_value = args[1]
        #         label = "$(label)[tick] t($(time_value))"

        #         # make transition
        #         transition = Tick!(c,time_value)
        #         success = true

        #     elseif kind ∈ [:send,:recv]
        #         @assert length(args)==1 "(Local) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
        #         message = args[1]
        #         action = Action(kind,message)

        #         # make transition
        #         transition = Act!(c,action)

        #         success = transition.success
        #         label = "$(label)[act] $(string(action)) [$(string(transition.resets)) ↦ 0]"

        #     else
        #         label = "$(label)ERROR"
        #         success = false
        #         @warn "(Local) Transition, unhandled kind: $(string(kind))."
        #     end

        #     new(origin,keep,label,success,kind,transition)

        # end
        "Handle Actions."
        Transition!(c::Social,a::Action,args...; keep::Bool = false) = TransitionSocial!(c,a.direction.dir,a.msg,args...;keep)


        "Transition for Social Configurations."
        Transition!(c::Social,kind::Symbol,args...; keep::Bool = false) = TransitionSocial!(c,kind,args...;keep)

        "Handle Actions."
        Transition!(c::System,a::Action,args...; keep::Bool = false) = TransitionSystem!(c,a.direction.dir,a.msg,args...;keep)


        "Transition for Social Configurations."
        Transition!(c::System,kind::Symbol,args...; keep::Bool = false) = TransitionSystem!(c,kind,args...;keep)
        # function Transition!(c::Social,kind::Symbol,args...; keep::Bool = false)

        #     @assert kind ∈ transition_labels "(Social) Transition kind ($(string(kind))) is not supported."

        #     if keep
        #         origin = c
        #     else
        #         origin = nothing
        #     end

        #     "Select (Social) Transition from kind."
        #     if kind==:t
        #         @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: time value."
        #         time_value = args[1]
        #         label = "t=$(time_value)"

        #         # make transition
        #         transition = Time!(c,time_value)

        #     elseif kind==:send
        #         @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
        #         message = args[1]
        #         action = Action(kind,message)
        #         label = string(action)

        #         # make transition
        #         transition = Send!(c,action)

        #         success = transition.success
        #         label = "$(label)[send] $(string(action)) [$(string(transition.resets)) ↦ 0]"
                
        #     elseif kind==:recv
        #         @assert length(args)==1 "(Social) Transition ($(string(kind))) expects 1 argument: message(label,payload)."
        #         message = args[1]
        #         action = Action(kind,message)
        #         label = string(action)

        #         # make transition
        #         transition = Que!(c,action)

        #         success = transition.success
        #         label = "$(label)[que] $(string(action))"


        #     elseif kind==:tau
        #         @assert length(args)==0 "(Social) Transition ($(string(kind))) expects 0 arguments, got: $(string(args))."
        #         action = Action(kind,message)

        #         # make transition
        #         transition = Recv!(c)

        #         success = transition.success
        #         label = "$(label)[recv] $(string(action)) [$(string(transition.resets)) ↦ 0]"

        #     else
        #         label = "ERROR"
        #         success = false
        #         @warn "(Social) Transition, unhandled kind: $(string(kind))."
        #     end

        #     new(origin,keep,label,success,kind,transition)

        # end

    end
    
    Base.show(t::Transition!,io::Core.IO = stdout) = print(io, string(t))

    Base.string(t::Transition!, args...) = string("↪$(t.label) $(t.success ? "⟶" : "̸⟶")")

    Base.show(t::TransitionLocal!,io::Core.IO = stdout) = print(io, string(t))

    Base.string(t::TransitionLocal!, args...) = string("↪$(t.label) $(t.success ? "⟶" : "̸⟶")")

    Base.show(t::TransitionSocial!,io::Core.IO = stdout) = print(io, string(t))

    Base.string(t::TransitionSocial!, args...) = string("↪$(t.label) $(t.success ? "⟶" : "̸⟶")")

    Base.show(t::TransitionSystem!,io::Core.IO = stdout) = print(io, string(t))

    Base.string(t::TransitionSystem!, args...) = string("↪$(t.label) $(t.success ? "⟶" : "̸⟶")")

end