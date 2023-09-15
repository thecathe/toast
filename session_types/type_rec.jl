module TypeRec

    import Base.show
    import Base.string

    using ..SessionTypes

    export μ

    mutable struct μ <: SessionType
        identity::String
        child::T where {T<:SessionType}
        μ(identity::String, child::T) where {T<:SessionType} = new(identity, child)
    end

    Base.show(s::μ, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::μ, mode::Symbol, io::Core.IO = stdout) = print(io, string(s, mode))

    # Base.string(s::μ, mode::Symbol = :default) = string("μα[$(s.identity)].", mode in [:full,:ext] ? mode==:full ? string(s.child, mode) : string(s.child) : "§")

    function Base.string(s::μ, mode::Symbol = :default) 
        str_base = string("μα[$(s.identity)].")
        if mode in [:default,:tail]
            # :default - string
            # :tail - show if 'end' or 'α'
            return string(str_base, string(s.child, :tail))

        elseif mode==:stub
            # :stub - string without child
            return str_base

        elseif mode==:expanded
            # :expanded - same as :full, with each tail expanded
            return string(str_base, string(s.child, :expanded))

        elseif mode==:full
            # :full - array of each line
            return Array{String}([string(str_base, string(s.child, :tail))])

        elseif mode==:full_expanded
            # :full_expanded - array of each line, with each tail expanded
            arr_child_tail = string(s.child, :full_expanded)
            @assert arr_child_tail isa Array "TypeRec.string (mode$(string(mode))), expected Array but got: $(string(typeof(arr_child_tail)))"
            
            str_children = Array{String}([])
            arr_child_len = length(arr_child_tail)
            # if arr_child_len==1 curr contains choice (possibly in tail)
            base_len = length(str_base)
            for y in 1:arr_child_len
                curr_child = arr_child_tail[y]
                if y==1
                    # add current interact with child
                    push!(str_children, string(string(s, :stub), curr_child))
                else
                    # add other child of tail, padd beginning to line up with parent interact
                    push!(str_children, string(repeat(" ", base_len), curr_child))
                end
            end
            return str_children

        elseif mode==:full_string
            # :full_string - stringify array of each line
            return string(join(string(s, :full), "\n"))

        elseif mode==:full_expanded_string
            # :full_string - stringify array of each line
            return string(join(string(s, :full_expanded), "\n"))

        else
            @error "TypeRec.string, unexpected mode: $(string(mode))"
        end
    end


end