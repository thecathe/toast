module TOAST

    include("clocks.jl")
    include("session_types.jl")

    using .Clocks
    using .SessionTypes

    # show(Msg("test", Data(3)))
    # show(Msg("test", Data(String)))

    show(S(Interaction(:send, Msg("a", Data(Int)), C(), [] )) )
    println()
    println()

    show(S(Interaction(:send, Msg("a", Data(Int)), C(), [], Interaction(:recv, Msg("b", Data(String)), C(), [], End()))) )
    println()
    println()

    show(S(Interaction(:send, Msg("a", Data(Int)), C(), [], Interaction(:recv, Msg("b", Data(String)), C(), []))) )
    println()
    println()

    show(S((:send, Msg("a", Data(Int)), C(), [] )) )
    println()
    println()

    show(S((:send, Msg("a", Data(Int)), C(), [], (:recv, Msg("b", Data(String)), C(), [], End()))) )
    println()
    println()

    show(S((:send, Msg("a", Data(Int)), C(), [], (:recv, Msg("b", Data(String)), C(), [] ))) )
    println()
    println()

    show(S(Choice([ (:send, Msg("a", Data(Int)), C(), []) ])))
    println()
    println()

    show(S(Choice([ 
        (:send, Msg("a", Data(Int)), C(), [], (:recv, Msg("b", Data(String)), C(), [], End())) 
        ])))
    println()
    println()

    show(S(Choice([ 
        (:send, Msg("a", Data(Int)), C(), [], (:recv, Msg("b", Data(String)), C(), [])) 
        ])))
    println()
    println()

    show(S(Choice([ 
        (:send, Msg("a", Data(Int)), C(), []), 
        (:send, Msg("c", Data(Int)), C(), []) 
        ])))
    println()
    println()

    show(S(Choice([ 
        (:send, Msg("a", Data(Int)), C(), []), 
        (:recv, Msg("b", Data(String)), C(), [], (:send, Msg("c", Data(Int)), C(), [])) 
        ])))
    println()
    println()

    show(S(Choice([ 
        (:send, Msg("a", Data(Int)), C(), []), 
        (:recv, Msg("b", Data(String)), C(), [], (:send, Msg("c", Data(Int)), C(), [])),
        (:send, Msg("d", Data(Int)), C(), [], Choice([
                (:send, Msg("e", Data(Int)), C(), []),
                (:send, Msg("f", Data(Int)), C(), [], (:send, Msg("g", Data(Int)), C(), []))
            ])) 
        ])))
    println()
    println()

    show(S(Def("a", (:send, Msg("a", Data(Int)), C(), [], (:send, Msg("a", Data(Int)), C(), [] ) ))) )
    println()
    println()

    show(S(Def("a",  Call("a") )) )
    println()
    println()

    show(S(Def("a", (:send, Msg("a", Data(Int)), C(), [], Call("a") ))) )
    println()
    println()

    show(S((:send, Msg("a", Data(Int)), C(), [], Def("a", (:send, Msg("a", Data(Int)), C(), [], Call("a")  ) ))) )
    println()
    println()

end