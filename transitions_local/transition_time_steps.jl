module TransitionTimeSteps

    import Base.show
    import Base.string
    
    using ..General
    using ..LogicalClocks
    using ..ClockValuations
    using ..Configurations

    export TimeStep!
    
    struct TimeStep!
        old::Clock
        v::Valuations
        t::TimeValue
        TimeStep!(c::T,t::TimeValue) where {T<:Configuration} = TimeStep!(c.valuations,t)
        TimeStep!(c::T,t::X) where {T<:Configuration,X<:Int} = TimeStep!(c.valuations,TimeValue(t))
        TimeStep!(c::Valuations,t::X) where {X<:Int} = TimeStep!(c,TimeValue(t))
        function TimeStep!(v::Valuations,t::TimeValue)
            _old = Clock(global_clock,v.system.value)
            v.system.value += t.value
            time_step!(v.clocks,t)
            new(_old,v,t)
        end
    end
    Base.show(t::TimeStep!,io::Core.IO = stdout) = print(io, string(t))
    Base.string(t::TimeStep!) = string(string(t.old) , " -($(string(t.t)))> ", string(t.v))
    
end