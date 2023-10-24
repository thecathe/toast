module SessionTypes

    export SessionType
    abstract type SessionType end

    include("session_types/type_end.jl")
    using .TypeEnd
    export End

    #
    # recursion
    #
    include("session_types/type_rec.jl")
    using .TypeRec
    export μ

    include("session_types/type_call.jl")
    using .TypeCall
    export α

    #
    # messages
    #
    include("session_types/type_direction.jl")
    using .TypeDirection
    export Direction, type_direction
    
    include("session_types/type_msg.jl")
    using .TypeMsg
    export Msg, Payload, None, SpecialPayload, supported_payload_datatypes

    #
    # communication
    #
    include("session_types/type_interact.jl")
    using .TypeInteract
    export Interact
    
    include("session_types/type_choice.jl")
    using .TypeChoice
    export Choice

    #
    # action (and lists)
    #
    include("session_types/type_action.jl")
    using .TypeAction
    export Action

    include("session_types/type_actions.jl")
    using .TypeActions
    export Actions

    include("session_types/type_msgs.jl")
    using .TypeMsgs
    export Msgs


    #
    # delegation
    #
    include("session_types/type_del.jl")
    using .TypeDel
    export Del

    #
    # duality
    #
    include("session_types/type_duality.jl")
    using .TypeDuality
    export Duality, dual

    #
    # generic wrapper
    #
    using ..LogicalClocks
    export S
    struct S <: SessionType

        #
        # interactions
        #
        S(direction::Direction,msg::Msg,constraints::δ,resets::λ,child::T=End()) where {T<:SessionType} = Interact(direction,msg,constraints,resets,child)
        
        # anonymous direction
        S(d::Symbol,msg::Msg,constraints::δ,resets::λ,child::T=End()) where {T<:SessionType} = Interact(Direction(d),msg,constraints,resets,child)
        
        # anonymous direction
        # anonymous message
        S(d::Symbol,msg::Tuple{String,DataType},constraints::δ,resets::λ,child::T=End()) where {T<:SessionType} = Interact(Direction(d),Msg(msg...),constraints,resets,child)

        #
        # choice
        #
        S(children::T) where {T<:Array{Interact}} = Choice(children)
        # single interact
        S(child::T) where {T<:Interact} = Choice([child])

    end

    # Base.show(s::S, io::Core.IO = stdout) = print(io, string(s))

    # Base.string(s::S) = 

end