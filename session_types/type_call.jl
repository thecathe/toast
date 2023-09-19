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

    function Base.string(s::α, args...) 
        # get mode
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        str_base = string("α[$(s.identity)]")

        if mode in [:default, :tail, :stub]
            # :default - string
            # :tail - show if 'end' or 'α'
            # :stub - string without child
            return str_base

        elseif mode==:expanded
            # :expanded - same as :full, with each tail expanded
            return str_base

        elseif mode in [:full,:full_expanded]
            # :full - array of each line
            if length(args)>1
                if args[2]==:str
                    return str_base
                elseif args[2]==:arr
                    return Array{String}([str_base])
                else
                    @error "Call.string, unexpected mode: $(string(args))"
                end
            else
                # default: arr
                return Array{String}([str_base])
            end

        else
            @error "TypeCall.string, unexpected mode: $(string(mode))"
        end
    end

end