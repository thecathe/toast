module TypeInteract

    import Base.show
    import Base.string

    using ..SessionTypes
    using ...LogicalClocks

    export Interact

    mutable struct Interact <: SessionType
        direction::Direction
        msg::Msg
        constraints::δ
        resets::λ
        child::T where {T<:SessionType}

        #
        Interact(direction::Direction,msg::Msg,constraints::δ,resets::λ,child::T=End()) where {T<:SessionType} = new(direction,msg,constraints,resets,child)

        # anonymous direction
        Interact(d::Symbol,msg::Msg,constraints::δ,resets::λ,child::T=End()) where {T<:SessionType} = Interact(Direction(d),msg,constraints,resets,child)
        
        # anonymous direction
        # anonymous message
        Interact(d::Symbol,msg::Tuple{String,DataType},constraints::δ,resets::λ,child::T=End()) where {T<:SessionType} = Interact(Direction(d),Msg(msg...),constraints,resets,child)
        
        # concat tail
        function Interact(a::T,b::Q) where {T<:Interact,Q<:SessionType} 
            if a.child isa End 
                return Interact(a.direction,a.msg,a.constraints,a.resets,b)
            else
                # add to tail of interact (requires chain of interact)
                return Interact(a.direction,a.msg,a.constraints,a.resets,Interact(a.child,b))
            end
        end
        
        # FIFO concat tail
        function Interact(choice::Array{T}) where {T<:SessionType}
            @assert choice[1] isa Interact "FIFO Interact tail, unexpected head type: $(string(typeof(choice[1])))"

            if length(choice) == 2
                return Interact(choice...)
            else
                # concat first tail with FIFO tail
                return Interact(choice[1],Interact(choice[2:end]))
            end
        end
    end

    Base.show(s::Interact, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::Interact, mode::Symbol, io::Core.IO = stdout) = print(io, string(s,mode))
    
    function Base.string(s::Interact, mode::Symbol = :default) 
        str_base = string(string(s.direction), "", string(s.msg), "(", string(s.constraints), ",", string(s.resets), ").")
        if mode==:default
            # :default - string
            return string(str_base, string(s.child, :tail))

        elseif mode==:stub
            # :stub - string without child
            return str_base

        elseif mode==:tail
            # :tail - show if 'end' or 'α'
            return string("§")

        elseif mode==:expanded
            # :expanded - same as :full, with each tail expanded
            return string(str_base, string(s.child, :expanded))

        elseif mode==:full
            # :full - array of each line
            return Array{String}([string(str_base, string(s.child, :tail))])

        elseif mode==:full_expanded
            # :full_expanded - array of each line, with each tail expanded
            arr_child_tail = string(s.child, :full_expanded)
            @assert arr_child_tail isa Array "TypeInteract.string (mode$(string(mode))), expected Array but got: $(string(typeof(arr_child_tail)))"
            
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
                    push!(str_children, string(repeat(" ", base_len-1), " ", curr_child))
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
            @error "TypeInteract.string, unexpected mode: $(string(mode))"
        end
    end

end