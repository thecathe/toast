module Clocks

    import Base.show
    import Base.string

    export Constraint, C

    abstract type Constraint end

    struct C <: Constraint end
    Base.string(c::C) = string("δ")

end