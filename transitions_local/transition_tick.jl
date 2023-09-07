module LocalTransitionTick

    import Base.show
    import Base.string
    
    using ..General
    using ..LogicalClocks
    using ..ClockValuations
    using ..Configurations

    using ..TransitionLabels

    export TimeStep!
    
    struct TimeStep!
        old::Clock
        v::Valuations
        t::UnitOfTime
        # time step configurations
        TimeStep!(c::T,t::UnitOfTime) where {T<:Configuration} = TimeStep!(c.valuations,t)
        # time step configurations (when given an int, check it is >= 0)
        TimeStep!(c::T,t::X) where {T<:Configuration,X<:Int} = TimeStep!(c.valuations,UnitOfTime(t))
        # time step over clock valuations
        TimeStep!(c::Valuations,t::X) where {X<:Int} = TimeStep!(c,UnitOfTime(t))
        function TimeStep!(v::Valuations,t::UnitOfTime)
            _old = Clock(global_clock,v.system.value)
            v.system.value += t.value
            time_step!(v.clocks,t)
            new(_old,v,t)
        end
    end
    Base.show(t::TimeStep!,io::Core.IO = stdout) = print(io, string(t))
    Base.string(t::TimeStep!) = string(string(t.old) , " -($(string(t.t)))> ", string(t.v))
    
end