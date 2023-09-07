module TypeEnd

    import Base.show
    import Base.string

    using ..SessionTypes

    export End

    struct End <: SessionType 
        End() = new()
    end
    Base.show(s::End, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::End, mode::Symbol = :default) = string("end")

end