module TypeMsgs

    import Base.show
    import Base.string

    using ..SessionTypes

    export Msgs

    struct Msgs
        children::Array{Msg}
        #
        Msgs(children::T) where {T<:Array{Msg}} = new(children)
        # extract from actions
        Msgs(actions::T) where {T<:Actions} = Msgs([a.msg for a in actions.children])
        # extract from choice
        Msgs(choice::T) where {T<:Choice} = Msgs([i.msg for i in choice.children])
    end

    Base.show(msgs::Msgs, io::Core.IO = stdout) = print(io, string(msgs))

    function Base.string(msgs::Msgs, mode::Symbol = :default) 
        if mode==:default
            return string(join(msgs.children,", "))
        else
            @error "Actions.string, unexpected mode: $(string(mode))"
        end
    end

end