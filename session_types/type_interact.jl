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
        if mode==:default 
            string(string(s.direction), "", string(s.msg), "(", string(s.constraints), ",", string(s.resets), ").", s.child isa End ? string(s.child) : "§")
        elseif mode==:full
            string(string(s.direction), "", string(s.msg), "(", string(s.constraints), ",", string(s.resets), ").",string(s.child,:full))
        elseif mode==:ext
            string(string(s.direction), "", string(s.msg), "(", string(s.constraints), ",", string(s.resets), ").",string(s.child))
        else
            @error "Interact.string, unexpected mode: $(string(mode))"
        end
    end

end