module TypeCall

    import Base.show
    import Base.string

    using ..SessionTypes

    export α

    struct α <: SessionType
        identity::String
        iteration::UInt8
        #
        α(iteration::UInt8=UInt8(0)) = new("",iteration)
        #
        α(identity::String,iteration::UInt8=UInt8(0)) = new(identity,iteration)
    end

    Base.show(s::α, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::α, mode::Symbol, io::Core.IO = stdout) = print(io, string(s, mode))

    Base.string(s::α, mode::Symbol = :default) = string("α[$(s.identity)]")

end