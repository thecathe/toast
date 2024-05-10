module LogicalClocks

    export Num
    const Num = T where {T<:Number}

    #
    # clock
    #
    include("logical_clocks/logical_clock.jl")
    using .LogicalClock
    export Clock
    
    include("logical_clocks/clock_resets.jl")
    using .ClockResets
    export λ
 
    #
    # valuations
    #
    include("logical_clocks/clock_valuations.jl")
    using .ClockValuations
    export ν, ValueOf!, ResetClocks!, TimeStep!, init!
    
    #
    # clock constraints
    #
    include("logical_clocks/constraints/clock_constraints.jl")
    using .ClockConstraints
    export δ, δExpr, δConjunctify, supported_constraints, format_constraints

    include("logical_clocks/constraints/constraint_normalisation.jl")
    using .ConstraintNormalisation
    export normaliseδ

    include("logical_clocks/constraints/difference_bound_constraints.jl")
    using .DifferenceBoundConstraints
    export DBC

    include("logical_clocks/constraints/bounds_of_constraints.jl")
    using .BoundsOfConstraints
    export δBounds

    include("logical_clocks/constraints/constraint_intersection.jl")
    using .ConstraintsIntersection
    export δIntersection

    #
    # weak past of constraints
    #
    include("logical_clocks/constraints/weak_past.jl")
    using .WeakPast
    export δ⬇

    #
    # constraint evaluation
    #
    include("logical_clocks/constraints/constraint_evaluation.jl")
    using .ConstraintEvaluation
    export δEvaluation!

end