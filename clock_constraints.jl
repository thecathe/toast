module ClockConstraints
    export Constraint, C

    using ..LogicalClocks

    abstract type Constraint end

    struct C <: Constraint end
    Base.string(c::C) = string("δ")
end