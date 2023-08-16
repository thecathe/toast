module TOAST

    show_clock_tests=false::Bool
    show_session_type_tests=true::Bool
    show_configuration_tests=false::Bool

    include("clocks.jl")
    using .Clocks

    if show_clock_tests

    end


    include("session_types.jl")
    using .SessionTypes

    if show_session_type_tests

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

    include("configurations.jl")
    using .Configurations

    if show_configuration_tests

    end

end