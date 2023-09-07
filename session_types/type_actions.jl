module TypeActions

    import Base.show
    import Base.string

    using ..SessionTypes

    export Actions

    struct Actions
        children::T where {T<:Array{Action}}
        # 
        Actions(children::T) where {T<:Array{Action}} = new(children)
        # extract from choice
        Actions(choice::T) where {T<:Choice} = Actions([Action(i) for i in choice.children])
    end

    Base.show(actions::Actions, io::Core.IO = stdout) = print(io, string(actions))

    function Base.string(actions::Actions, mode::Symbol = :default) 
        if mode==:default
                return string(join(actions.children,", "))
        else
                @error "Actions.string, unexpected mode: $(string(mode))"
        end
    end

end