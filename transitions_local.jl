module TransitionsLocal

    include("transition_labels.jl")
    using .TransitionLabels
    export TransitionLabel, transition_labels


    using ..Configurations

    struct LocalTransition 
        valid::Bool
        label::TransitionLabel
    end
    export LocalTransition

    # abstract type LocalTransitionOp end
    # export LocalTransitionOp, LocalTransition

    # struct LocalTransition
    #     old_config::T where {T<:Configuration}
    #     operation::R where {R<:LocalTransitionOp}

    #     function LocalTransition(head::Symbol,c::T,args...) where {T<:Configuration}

    #         @assert head ∈ transition_labels "LocalTransition, unexpected head: $(string(head))."

    #         if head==:t
    #             @assert length(args)==1 "LocalTransition (:t), expects time value. (given $(string(lenght(args))) args.)"
    #             new(c,Tick!(c,args[1]))
    #         else
    #             @warn "LocalTransition, unexpected head: $(string(head))."
    #         end
    #     end
    # end


    include("transitions_local/transition_tick.jl")
    using .LocalTransitionTick
    export Tick!
    
    # include("transitions_local/transition_act.jl")
    # using .LocalTransitionActionSteps
    # # export 

    # include("transitions_local/transition_unfold.jl")
    # using .LocalTransitionUnfolds
    # # export 

end