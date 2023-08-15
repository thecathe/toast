module TOAST

    include("clocks.jl")
    include("session_types.jl")

    using .Clocks
    using .SessionTypes

    # show(Msg("test", Data(3)))

    show(S(Choice([ (:send, Msg("test", Data(3)), C(), []) ])))

end