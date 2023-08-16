module Configurations

    import Base.show
    import Base.string
    
    using ..LogicalClocks
    using ..SessionTypes

    abstract type Configuration end

    struct Local <: Configuration
        clocks::Clocks
    end

end