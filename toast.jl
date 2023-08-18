module TOAST

    show_all_tests=false

    show_logical_clock_tests=false
    show_clock_constraints_tests=false
    show_session_type_tests=false
    show_clock_valuations_tests=true
    show_evaluate_tests=true
    show_configuration_tests=false

    module General

        import Base.show
        import Base.string
        import Base.convert
        import Base.getindex
        import Base.iterate
        import Base.push!
        import Base.length
        import Base.isempty
        
        export Label, Labels
        const Label = String 
        # const Labels = Array{Label}
        struct Labels
            children::Array{Label}
            distinct::Bool
            function Labels(children,distinct=false) 
                if distinct
                    return new(unique(children),distinct)
                else
                    return new(children,distinct)
                end
            end
        end

        Base.show(l::Labels, io::Core.IO = stdout) = print(io, string(l))
        Base.string(l::Labels) = isempty(l) ? string("∅") : string("{", join(l, ", "), "}")
        
        Base.convert(::Type{Array{Label}}, l::T) where {T<:Vector{Any}} = Array{Label}(l)
        
        Base.push!(l::Labels, a::Label) = push!(l.children, a)

        Base.length(l::Labels) = length(l.children)
        Base.isempty(l::Labels) = isempty(l.children)
        Base.getindex(l::Labels, i::Int) = getindex(l.children, i)

        Base.iterate(l::Labels) = isempty(l) ? nothing : (getindex(l,1), Int(1))
        Base.iterate(l::Labels, i::Int) = (i >= length(l)) ? nothing : (getindex(l,i+1), i+1)

        export Num
        const Num = T where {T<:Number}
    end

    using .General
        
    function printlines() 
        println()
        println()
        # println()
    end

    include("logical_clocks.jl")
    using .LogicalClocks

    if show_logical_clock_tests || show_all_tests
        println("logical clock tests:")

        clocks = Clocks([("a",1),("b",2),("c",3)])

        show(string(clocks,true))
        printlines()
        
        show(string(value!(clocks,"a"),true))
        printlines()
        
        show(string(value!(clocks,"z"),true))
        printlines()
        
        show(string(clocks,true))
        printlines()

        reset!(clocks,[])
        show(string(clocks,true))
        printlines()
        
        reset!(clocks,["a","b"])
        show(string(clocks,true))
        printlines()
        
        time_step!(clocks, 3)
        show(string(clocks,true))
        printlines()
        
        reset!(clocks,["a","b"])
        show(string(clocks,true))
        printlines()
        
    end



    include("clock_constraints.jl")
    using.ClockConstraints

    if show_clock_constraints_tests || show_all_tests
        println("clock constraints tests:")

        show(δ(:and, δ(:not, δ(:tt)), δ(:tt)))
        printlines()

        a = δ(:eq, "x", 3)
        show(a)
        printlines()

        b = δ(:not, δ(:eq, "x", 3))
        show(b)
        printlines()

        c = δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4))
        show(c)
        printlines()

        d = δ(:deq, "x", "y", 3)
        show(d)
        printlines()


        e = δ(:and, δ(:not, δ(:and, δ(:eq, "w", 3), δ(:geq, "x", 4))), δ(:and, δ(:eq, "y", 3), δ(:geq, "z", 4)))   
        show(e)
        printlines()

        f = flatten(e)
        show(f)
        printlines()

        g = ConstrainedClocks(f)
        show(g)
        printlines()

    end



    include("session_types.jl")
    using .SessionTypes

    if show_session_type_tests || show_all_tests
        println("session type tests:")

        show(S(Interaction(:send, Msg("a", Data(Int)), δ(:tt), [] )) )
        printlines()

        show(S(Interaction(:send, Msg("a", Data(Int)), δ(:tt), [], Interaction(:recv, Msg("b", Data(String)), δ(:tt), [], End()))) )
        printlines()

        show(S(Interaction(:send, Msg("a", Data(Int)), δ(:tt), [], Interaction(:recv, Msg("b", Data(String)), δ(:tt), []))) )
        printlines()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [] )) )
        printlines()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [], End()))) )
        printlines()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [] ))) )
        printlines()

        show(S(Choice([ (:send, Msg("a", Data(Int)), δ(:tt), []) ])))
        printlines()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [], End())) 
            ])))
        printlines()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [])) 
            ])))
        printlines()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), []), 
            (:send, Msg("c", Data(Int)),δ(:tt), []) 
            ])))
        printlines()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), []), 
            (:recv, Msg("b", Data(String)), δ(:tt), [], (:send, Msg("c", Data(Int)), δ(:tt), [])) 
            ])))
        printlines()

        show(S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), []), 
            (:recv, Msg("b", Data(String)), δ(:tt), [], (:send, Msg("c", Data(Int)), δ(:tt), [])),
            (:send, Msg("d", Data(Int)), δ(:tt), [], Choice([
                    (:send, Msg("e", Data(Int)), δ(:tt), []),
                    (:send, Msg("f", Data(Int)), δ(:tt), [], (:send, Msg("g", Data(Int)), δ(:tt), []))
                ])) 
            ])))
        printlines()

        show(S(Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], (:send, Msg("a", Data(Int)), δ(:tt), [] ) ))) )
        printlines()

        show(S(Def("a",  Call("a") )) )
        printlines()

        show(S(Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], Call("a") ))) )
        printlines()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [], Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], Call("a")  ) ))) )
        printlines()
    end

 
    include("clock_valuations.jl")
    using .ClockValuations

    if show_clock_valuations_tests || show_all_tests
        println("clock valuation tests:")

        clocks = Clocks([("a",1),("b",2),("c",3)])
        
        a = Valuations(clocks)
        show(a)
        printlines() 

        show(TimeStep!(a,1))
        printlines() 

        show(Reset!(a,["b","c","y"]))
        printlines() 

        show(Value!(a,"z"))
        printlines() 

        show(TimeStep!(a,3))
        printlines() 

    end

    
    include("evaluate.jl")
    using .Evaluate

    if show_evaluate_tests || show_all_tests
        println("evaluate tests:")

        clocks = Clocks([("a",1),("b",2),("c",3)])
        v = Valuations(clocks)

        # show(v)
        # printlines()

        a = δ(:eq, "x", 3)
        # b = δ(:not, a)
        # c = δ(:and, a, δ(:geq, "y", 4))
        b = δ(:not, δ(:eq, "a", 3))
        c = δ(:and, δ(:eq, "a", 1), δ(:geq, "c", 2))
        d = δ(:deq, "c", "y", 3)
        e = δ(:and, δ(:not, δ(:and, δ(:eq, "b", 1), δ(:geq, "x", 4))), δ(:and, δ(:eq, "a", 3), δ(:geq, "z", 4)))   


        show(v)
        println()
        show(Eval(v,a))
        printlines()

        show(v)
        println()
        show(Eval(v,b))
        printlines()
        
        show(v)
        println()
        show(Eval(v,c))
        printlines()
        
        show(v)
        println()
        show(Eval(v,d))
        printlines()
        
        show(v)
        println()
        show(Eval(v,e))
        printlines()

        printlines()
        show(TimeStep!(v,3))
        printlines()
        printlines() 

        show(v)
        println()
        show(Eval(v,a))
        printlines()

        show(v)
        println()
        show(Eval(v,b))
        printlines()
        
        show(v)
        println()
        show(Eval(v,c))
        printlines()
        
        show(v)
        println()
        show(Eval(v,d))
        printlines()
        
        show(v)
        println()
        show(Eval(v,e))
        printlines()

        # show(a)
        # printlines()

        # show(b)
        # printlines()

        # show(c)
        # printlines()

        # show(d)
        # printlines()

    end


    
    include("configurations.jl")
    using .Configurations

    if show_configuration_tests || show_all_tests
        println("configuration tests:")

    end

end