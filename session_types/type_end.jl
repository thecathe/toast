module TypeEnd

    import Base.show
    import Base.string

    using ..SessionTypes

    export End

    struct End <: SessionType 
        End() = new()
    end

    Base.show(s::End, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::End, mode::Symbol, io::Core.IO = stdout) = print(io, string(s, mode))

    function Base.string(s::End, args...) 
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        str_base = string("end")

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
                    @error "End.string, unexpected mode: $(string(args))"
                end
            else
                # default: arr
                return Array{String}([str_base])
            end
            
        else
            @error "TypeEnd.string, unexpected mode: $(string(mode))"
        end
    end

end