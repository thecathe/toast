module TOAST

    module General
        
        export Label, Labels
        const Label = String 
        const Labels = Array{Label}
        Base.show(l::Labels, io::Core.IO = stdout) = print(io, string(l))
        Base.string(l::Labels) = isempty(l) ? string("∅") : string("{", join(l), "}")
        
        Base.convert(::Type{Array{Label}}, l::T) where {T<:Vector{Any}} = Array{Label}(l)
    end

    using .General
        

    show_logical_clock_tests=true::Bool
    show_session_type_tests=false::Bool
    show_configuration_tests=false::Bool

    include("logical_clocks.jl")
    using .LogicalClocks

    if show_logical_clock_tests

        clocks = Clocks([("a",1),("b",2),("c",3)])

        show(clocks)
        println()
        println()
        
        show(value!(clocks,"a"))
        println()
        println()
        
        show(value!(clocks,"z"))
        println()
        println()
        
        show(clocks)
        println()
        println()

        reset!(clocks,[])
        show(clocks)
        println()
        println()
        
        reset!(clocks,["a","b"])
        show(clocks)
        println()
        println()
        
        time_step!(clocks, 3)
        show(clocks)
        println()
        println()
        
        reset!(clocks,["a","b"])
        show(clocks)
        println()
        println()
        
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