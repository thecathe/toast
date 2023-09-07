module TypeDirection

    import Base.show
    import Base.string

    export Direction, type_direction
    const type_direction = [:send, :recv]

    struct Direction
        child::Symbol
        function Direction(child::Symbol)
            @assert child in type_direction "Direction, unexpected: $(string(child))"

            new(child)
        end
    end

    Base.show(d::Direction, io::Core.IO = stdout) = print(io, string(d))

    Base.string(d::Direction) = string(d.child==:send ? "!" : "?")

end