module Evaluate

    import Base.show
    import Base.string
    import Base.convert
    
    using ..LogicalClocks
    using ..ClockConstraints
    using ..ClockValuations

    # evaluate constraint against clocks
    struct Eval
        v::Valuations
        δ::Constraints
        child::Expr
        function Eval(v,δ)
            # make sure all clocks are initialised
            _constrained::Labels = ConstrainedClocks(δ)
            foreach(l -> value!(v,l), _constrained)
            _labels = labels(v)
            @assert foreach(l -> l in _labels, _constrained)

            # TODO: make new Expr, replacing clock labels with values
            # store result in child

            new(v,δ,~)
        end
    end

end