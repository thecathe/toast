# ENV["JULIA_DEBUG"] = "all"

module TOAST

    function printlines() 
        println()
        println()
    end
    printlines()

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

    begin
        a = End()
        b = Interact(:recv,"b",δ(:eq,"x",3),λ())
        c = α("r")
        d = Interact(b,c)
        e = μ("r",d)

        type = e

        # env = RecEnv([("r",δ(:eq,"x",1))])
        env = RecEnv([("a",δ(:eq,"x",1))])

        constraints = δ(:ff)

        # is_wf = IsWellformed(type,constraints,env)

        # show(is_wf)
    end

    begin
        a = δ(:eq, "x", 4)
        b = δ(:gtr, "x", 2)
        c = δ(:and, δ(:geq, "x", 3), δ(:not, δ(:gtr, "x", 5)))
        g = δ(:or, δ(:geq, "x", 3), δ(:not, δ(:gtr, "x", 5)))
        d = δ(:or, δ(:les, "x", 3), δ(:gtr, "x", 5))

        e = δ(:eq, "x", 5)
        f = δ(:or, δ(:les, "x", 3), δ(:geq, "x", 5))
        

        # bounds = δBounds(a;normalise=true)
        
        # @info string("a: $(string(a))\nnormalised: $(string(normaliseδ(a)))\nbounds: $(string(δBounds(a;normalise=true)))")
        # printlines()
        # @info string("b: $(string(b))\nnormalised: $(string(normaliseδ(b)))\nbounds: $(string(δBounds(b;normalise=true)))")
        # printlines()
        # @info string("c: $(string(c))\nnormalised: $(string(normaliseδ(c)))\nbounds: $(string(δBounds(c;normalise=true)))")
        # printlines()

        @info string("a ∩ b ≡ ($(string(a)) ∩ $(string(b))) ≡ ($(string(a,:norm)) ∩ $(string(b,:norm))) ≡ $(string(δIntersection(a,b)))")
        printlines()
        @info string("a ∩ c ≡ ($(string(a)) ∩ $(string(c))) ≡ ($(string(a,:norm)) ∩ $(string(c,:norm))) ≡ $(string(δIntersection(a,c)))")
        printlines()
        @info string("a ∩ g ≡ ($(string(a)) ∩ $(string(g))) ≡ ($(string(a,:norm)) ∩ $(string(g,:norm))) ≡ $(string(δIntersection(a,g)))")
        printlines()
        @info string("b ∩ c ≡ ($(string(b)) ∩ $(string(c))) ≡ ($(string(b,:norm)) ∩ $(string(c,:norm))) ≡ $(string(δIntersection(b,c)))")
        printlines()
        @info string("a ∩ d ≡ ($(string(a)) ∩ $(string(d))) ≡ ($(string(a,:norm)) ∩ $(string(d,:norm))) ≡ $(string(δIntersection(a,d)))")
        printlines()
        @info string("e ∩ f ≡ ($(string(e)) ∩ $(string(f))) ≡ ($(string(e,:norm)) ∩ $(string(f,:norm))) ≡ $(string(δIntersection(e,f)))")
        printlines()

    end






    printlines()

end