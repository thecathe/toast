module TypeRec

    import Base.show
    import Base.string

    using ..SessionTypes

    export μ

    mutable struct μ <: SessionType
        identity::String
        child::T where {T<:SessionType}
        iteration::UInt8
        μ(identity::String, child::T, iteration::UInt8 = UInt8(0)) where {T<:SessionType} = new(identity, child, iteration)
    end

    Base.show(s::μ, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::μ, mode::Symbol, io::Core.IO = stdout) = print(io, string(s, mode))

    # Base.string(s::μ, mode::Symbol = :default) = string("μα[$(s.identity)].", mode in [:full,:ext] ? mode==:full ? string(s.child, mode) : string(s.child) : "§")

    function Base.string(s::μ, args...) 
        # get mode
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        str_base = string("μα[$(s.identity)$(s.iteration==0 ? "" : "($(s.iteration))")].")

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
            str_children = Array{String}([string(str_base, string(s.child, :tail))])

            # how to return? (default: str)
            if length(args)>1
                second_mode = args[2]
            else
                second_mode = :str
            end
            if second_mode==:str
                return string(join(str_children, "\n"))
            elseif second_mode==:arr
                return str_children
            else
                @error "Rec.string, unexpected second mode: $(string(second_mode))"
            end

        elseif mode==:full_expanded
            # :full_expanded - array of each line, with each tail expanded
            arr_child_tail = string(s.child, :full_expanded,:arr)
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
            
            # how to return? (default: str)
            if length(args)>1
                second_mode = args[2]
            else
                second_mode = :str
            end
            if second_mode==:str
                return string(join(str_children, "\n"))
            elseif second_mode==:arr
                return str_children
            else
                @error "Rec.string, unexpected second mode: $(string(args))"
            end

        else
            @error "Rec.string, unexpected mode: $(string(args))"
        end
    end


end