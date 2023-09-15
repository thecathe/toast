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

    function Base.string(s::End, mode::Symbol = :default) 
        str_base = string("end")
        if mode in [:default, :tail, :stub, :full_string, :full_expanded_string]
            # :default - string
            # :tail - show if 'end' or 'α'
            # :stub - string without child
            return str_base

        elseif mode==:expanded
            # :expanded - same as :full, with each tail expanded
            return str_base

        elseif mode in [:full,:full_expanded]
            # :full - array of each line
            return Array{String}([str_base])
            
        else
            @error "TypeEnd.string, unexpected mode: $(string(mode))"
        end
    end

end