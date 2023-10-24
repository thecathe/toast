module TypeDirection

    import Base.show
    import Base.string

    export Direction, type_direction
    const type_direction = [:send, :recv]

    struct Direction
        dir::Symbol
        function Direction(dir::Symbol)
            @assert dir in type_direction "Direction, unexpected: $(string(dir))."

            new(dir)
            # return dir
        end
    end

    Base.show(d::Direction, io::Core.IO = stdout) = print(io, string(d))

    Base.string(d::Direction) = string(d.dir==:send ? "!" : "?")

end