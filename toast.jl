# ENV["JULIA_DEBUG"] = "all"

module TOAST

    function printlines() 
        println()
        println()
    end

    #
    # clocks and constraints
    #
    include("logical_clocks.jl")
    using .LogicalClocks
    export Num
    export Clock, λ
    export ν, ValueOf!, ResetClocks!, TimeStep!
    export δ, supported_constraints
    export δExpr, normaliseδ, DBC, δBounds
    export δ⬇, δEvaluation!

    #
    # session types and actions
    #
    include("session_types.jl")
    using .SessionTypes
    export End, μ, α, Interact, Choice
    export Msgs, Msg, Payload, Del
    export Actions, Action
    export SessionType, S
    export Duality, dual
    
    #
    # configurations and enabled actions
    #
    include("configurations.jl")
    using .Configurations
    export Local, Social, System
    export Queue, head!
    export Evaluate!

    #
    # operational semantics of configurations
    #
    include("transitions.jl")
    using .Transitions
    export Transition!
    
    export Tick!, Act!, Unfold!
    export Que!, Send!, Recv!, Time!
    export Wait!, Par!, Com!

    #
    # well-formedness rules of types
    #
    include("wellformedness_rules.jl")
    using .WellformednessRules
    export IsWellformed
    # export WfRuleEnd

    a = End()
    b = Interact(:recv,"b",δ(:eq,"x",3),λ(),a)
    c = α("r")
    # d = μ("r",c)
    d = μ("r",a)

    type = d

    # env = RecEnv([("r",δ(:eq,"x",1))])
    env = RecEnv([("a",δ(:eq,"x",1))])

    constraints = δ(:ff)

    is_wf = IsWellformed(type,constraints,env)

    show(is_wf)








end