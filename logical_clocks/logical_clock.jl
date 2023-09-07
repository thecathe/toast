module LogicalClock

    import Base.show
    import Base.string

    using ..LogicalClocks

    export Clock
    
    mutable struct Clock
        label::String
        value::UInt8
        #
        Clock(label::String,value::Num) = new(label,UInt8(value))
        # swapped
        Clock(value::Num,label::String) = new(label,UInt8(value))
    end

    Base.show(c::Clock, io::Core.IO = stdout) = print(io, string(c))
    Base.show(c::Clock, mode::Symbol, io::Core.IO = stdout) = print(io, string(c, mode))

    function Base.string(c::Clock, mode::Symbol = :default) 
        if mode==:default
            string("[", c.label, ": ", c.value, "]")
        else
            @error "Clock.string, unexpected mode: $(string(mode))"
        end
    end

end