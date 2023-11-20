module LogicalClock

    import Base.show
    import Base.string

    using ..LogicalClocks

    export Clock
    
    mutable struct Clock
        label::String
        value::Num
        Clock(label::String,value::Num) = new(label,Num(value))
        Clock(value::Num,label::String) = new(label,Num(value))
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