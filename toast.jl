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
        
    show_all_tests=true

    show_logical_clock_tests=false
    show_clock_constraints_tests=false
    show_session_type_tests=false
    show_configuration_tests=false



    include("logical_clocks.jl")
    using .LogicalClocks

    if show_logical_clock_tests || show_all_tests

        clocks = Clocks([("a",1),("b",2),("c",3)])

        show(string(clocks,true))
        println()
        println()
        
        show(string(value!(clocks,"a"),true))
        println()
        println()
        
        show(string(value!(clocks,"z"),true))
        println()
        println()
        
        show(string(clocks,true))
        println()
        println()

        reset!(clocks,[])
        show(string(clocks,true))
        println()
        println()
        
        reset!(clocks,["a","b"])
        show(string(clocks,true))
        println()
        println()
        
        time_step!(clocks, 3)
        show(string(clocks,true))
        println()
        println()
        
        reset!(clocks,["a","b"])
        show(string(clocks,true))
        println()
        println()
        
    end



    include("clock_constraints.jl")
    using.ClockConstraints

    if show_clock_constraints_tests || show_all_tests

        show(δ(:and, δ(:not, δ(:tt)), δ(:tt)))
        println()
        println()

        a = δ(:eq, "x", 3)
        show(a)
        println()
        println()

        b = δ(:not, δ(:eq, "x", 3))
        show(b)
        println()
        println()

        c = δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4))
        show(c)
        println()
        println()

        d = δ(:deq, "x", "y", 3)
        show(d)
        println()
        println()


        e = δ(:and, δ(:not, δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4))), δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4)))   
        show(e)
        println()
        println()

        show(flatten(e))
        println()
        println()

    end



    include("session_types.jl")
    using .SessionTypes

    if show_session_type_tests || show_all_tests

        show(S(Interaction(:send, Msg("a", Data(Int)), δ(:tt), [] )) )
        println()
        println()

        show(S(Interaction(:send, Msg("a", Data(Int)), δ(:tt), [], Interaction(:recv, Msg("b", Data(String)), δ(:tt), [], End()))) )
        println()
        println()

        show(S(Interaction(:send, Msg("a", Data(Int)), δ(:tt), [], Interaction(:recv, Msg("b", Data(String)), δ(:tt), []))) )
        println()
        println()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [] )) )
        println()
        println()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [], End()))) )
        println()
        println()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [] ))) )
        println()
        println()

        show(S(Choice([ (:send, Msg("a", Data(Int)), δ(:tt), []) ])))
        println()
        println()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [], End())) 
            ])))
        println()
        println()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [])) 
            ])))
        println()
        println()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), []), 
            (:send, Msg("c", Data(Int)),δ(:tt), []) 
            ])))
        println()
        println()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), []), 
            (:recv, Msg("b", Data(String)), δ(:tt), [], (:send, Msg("c", Data(Int)), δ(:tt), [])) 
            ])))
        println()
        println()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), []), 
            (:recv, Msg("b", Data(String)), δ(:tt), [], (:send, Msg("c", Data(Int)), δ(:tt), [])),
            (:send, Msg("d", Data(Int)), δ(:tt), [], Choice([
                    (:send, Msg("e", Data(Int)), δ(:tt), []),
                    (:send, Msg("f", Data(Int)), δ(:tt), [], (:send, Msg("g", Data(Int)), δ(:tt), []))
                ])) 
            ])))
        println()
        println()

        show(S(Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], (:send, Msg("a", Data(Int)), δ(:tt), [] ) ))) )
        println()
        println()

        show(S(Def("a",  Call("a") )) )
        println()
        println()

        show(S(Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], Call("a") ))) )
        println()
        println()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [], Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], Call("a")  ) ))) )
        println()
        println()
    end


    
    include("configurations.jl")
    using .Configurations

    if show_configuration_tests || show_all_tests

    end

end