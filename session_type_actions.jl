module SessionTypeActions

    import Base.show
    import Base.string
    import Base.convert

    using ..General
    using ..SessionTypes

    export Action 

    struct Action
        direction::Symbol
        msg::Msg
        post::Labels
        Action(i::Interaction) = Action(i.direction,i.msg,i.resets)
        Action(direction::Symbol,msg::Msg,resets::Labels=Labels([])) = new(direction,msg,resets)
    end
    Base.show(s::Action, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Action) = string(string(s.direction == :send ? "!" : s.direction == :recv ? "?" : "□"), " ", string(s.msg))

    # Base.convert(::Type{Action}, t::T) where {T<:Tuple{Symbol,Msg}} = Action(t...)


end