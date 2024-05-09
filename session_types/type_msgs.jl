module TypeMsgs

    import Base.show
    import Base.string

    import Base.length
    import Base.isempty

    import Base.push!

    import Base.getindex
    import Base.deleteat!
    import Base.iterate

    using ..SessionTypes

    export Msgs

    struct Msgs
        children::Array{Msg}
        # empty
        Msgs() = Msgs(Array{Msg}([]))
        Msgs(msg::Msg) = Msgs(Array{Msg}([msg]))
        # extract from actions
        Msgs(actions::T) where {T<:Actions} = Msgs(Array{Msg}([a.msg for a in actions.children]))
        # extract from choice
        Msgs(choice::T) where {T<:Choice} = Msgs(Array{Msg}([i.msg for i in choice.children]))
        #
        Msgs(children::T) where {T<:Array{Msg}} = new(children)
    end

    Base.show(msgs::Msgs, io::Core.IO = stdout) = print(io, string(msgs))

    function Base.string(msgs::Msgs, mode::Symbol = :default) 
        if mode==:default
            return string(join(msgs.children,", "))
        else
            @error "Actions.string, unexpected mode: $(string(mode))"
        end
    end
    
    Base.length(m::Msgs) = length(m.children)
    Base.isempty(m::Msgs) = isempty(m.children)

    Base.getindex(m::Msgs, i::Int) = getindex(m.children,i)
    Base.deleteat!(m::Msgs, i::Int) = deleteat!(m.children,i)

    Base.push!(msgs::Msgs,m::Msg) = push!(msgs.children,m)

    Base.iterate(m::Msgs) = isempty(m) ? nothing : (m[1], Int(1))
    Base.iterate(m::Msgs, i::Int) = i>=length(m) ? nothing : (m[i+1], i+1)

end