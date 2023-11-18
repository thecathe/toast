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

    export Transition!


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
    export Com!#, ComL!, ComR!

    include("transitions/transitions_system/transition_par.jl")
    using .SystemTransitionPar
    export Par!#, ParL!, ParR!

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


        "Handle Actions."
        Transition!(c::Social,a::Action,args...; keep::Bool = false) = TransitionSocial!(c,a.direction.dir,a.msg,args...;keep)
        "Transition for Social Configurations."
        Transition!(c::Social,kind::Symbol,args...; keep::Bool = false) = TransitionSocial!(c,kind,args...;keep)


        "Handle Actions."
        Transition!(c::System,a::Action,args...; keep::Bool = false) = TransitionSystem!(c,a.direction.dir,a.msg,args...;keep)
        "Transition for Social Configurations."
        Transition!(c::System,kind::Symbol,args...; keep::Bool = false) = TransitionSystem!(c,kind,args...;keep)
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