module SessionTypeActions

    import Base.show
    import Base.string

    using ..General
    using ..SessionTypes

    export Action 

    struct Action
        direction::Symbol
        msg::Msg
        post::Labels
        function Action(interaction::Interaction)
            _dir=interaction.direction
            _msg=interaction.msg
            # _label=string(string(_dir),string(_msg))
            new(_dir,_msg,Labels(interaction.λ))
        end
    end
    Base.show(s::Action, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::Action) = string("(", string(s.direction == :send ? "!" : s.direction == :recv ? "?" : "□"), " ", string(s.msg), ")")



end