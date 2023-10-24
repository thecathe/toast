module TypeAction

    import Base.show
    import Base.string

    using ..SessionTypes

    export Action

    struct Action 
        direction::Direction
        msg::Msg
        # extract from interaction
        Action(interact::T) where {T<:Interact} = Action(interact.direction,interact.msg)
        # handle Symbol
        Action(direction::Symbol,msg::Msg) = Action(Direction(direction),msg)
        # constuct action
        Action(direction::Direction,msg::Msg) = new(direction,msg)
    end
    Base.show(action::Action,io::Core.IO = stdout) = print(io,string(action))
    Base.string(action::Action) = string(string(action.direction),string(action.msg))

end