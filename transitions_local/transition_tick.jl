module LocalTransitionTick

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    using ..TransitionsLocal

    export Tick!
    
    @doc raw"""
    ```math
       (ν, S) \stackrel{⟶}{t} (ν+t, S)
    ```
    """
    struct Tick! <: LocalTransition
        old_config::Local
        time::TimeStep!

        # social configs
        Tick!(c::Social,t::Num) = Tick!(Local(c),UInt8(t))
        Tick!(c::Social,t::UInt8) = Tick!(Local(c),t)

        # time step over clock valuations
        Tick!(l::Local,t::Num) = TimeStep!(l,UInt8(t))

        function Tick!(l::Local,t::UInt8)

            old_config = l
        
            time = TimeStep!(l.valuations,t)

            new(old_config,time)
        end
    end

    Base.show(t::Tick!,io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::Tick!, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))
    Base.show(t::Tick!, modes::T, io::Core.IO = stdout) where {T<:Array{Symbol}}= print(io, string(t, modes...))

    function Base.string(t::Tick!, args...) 
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        if mode==:default
            string("↪[tick]", string(t.time))
        else
            @warn "string.Tick!, unexpected mode: $(string(mode)), [$(string(join(args,", ")))]."
        end
    end
    
end