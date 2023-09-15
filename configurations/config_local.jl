module LocalConfigurations

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes

    export Local

    struct Local
        valuations::Valuations
        type::S

        function Local(val::Valuations,type::S)

            if type isa Choice || type isa Interact
                # populate immediately relevant clocks
            end

            new(val,type)

        end
    end

    Base.show(c::Local, io::Core.IO = stdout) = print(io, string(c))
    Base.show(c::Local, mode::symbol, io::Core.IO = stdout) = print(io, string(c, mode))

    function Base.string(c::Local, mode::Symbol=:default)
        if mode==:default
            return string("")
        end
    end

end