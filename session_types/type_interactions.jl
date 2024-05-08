module TypeInteractions

    import Base.show
    import Base.string
    
    import Base.in
    import Base.get
    import Base.findall

    import ..SessionTypes.Direction
    import ..SessionTypes.Msg
    import ..SessionTypes.Action
    import ..SessionTypes.Interact

    # as in Evaluate!

    Base.in(label::String, collection::Array{Interact}) = in(Msg(label), collection)

    "Returns true if collection contains interaction with Msg."
    function Base.in(msg::Msg, collection::Array{Interact})
        isin = get(collection, msg, false)
        if isin isa Bool
            return isin
        else
            return true
        end
    end

    Base.in(dir::Symbol, collection::Array{Interact}) = in(Direction(dir), collection)
    
    "Returns true if collection contains interaction with direction."
    function Base.in(dir::Direction, collection::Array{Interact})
        all = findall(dir, collection)
        return length(all)>0
    end
    
    "Returns true if collection contains interaction with action."
    Base.in(action::Action, collection::Array{Interact}) = in(action.direction, collection) && in(action.msg, collection)
    

    "Get interaction with matching label."
    function Base.get(s::Array{Interact},label::String,default=nothing)
        for interact in s
            if interact.msg.label==label 
                return interact
            end
        end
        return default
    end

    Base.get(s::Array{Interact},msg::Msg,default=nothing) = Base.get(s,msg.label,default)
    
    Base.get(s::Array{Interact},interact::Interact,default=nothing) = Base.get(s,interact.msg.label,default)

    Base.findall(dir::Symbol,s::Array{Interact}) = findall(Direction(dir),s)

    "Findall interactions with matching direction."
    function Base.findall(dir::Direction, s::Array{Interact})
        collection = Array{Interact}([])
        for interact in s
            if interact.direction==dir
                push!(collection,interact)
            end
        end
        return collection
    end

    Base.show(s::Array{Interact}, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::Array{Interact}, mode::Symbol, io::Core.IO = stdout) = print(io, string(s,mode))
    
    function Base.string(s::Array{Interact}, args...)
        if length(s)==0
            "∅"
        else
            "$(string([string(i) for i in s]))"
        end
    end


end