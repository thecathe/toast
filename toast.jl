module TOAST

    show_all_tests=true

    show_logical_clock_tests=false
    show_clock_constraints_tests=false
    show_session_type_tests=false
    show_clock_valuations_tests=false
    show_evaluate_tests=false
    show_configuration_tests=false
    show_transition_tests=true

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

        abstract type LabelList end

        struct Labels <: LabelList
            children::Array{Label}
            distinct::Bool
            # Labels(distinct=false) = new(Array{Label}([]),distinct)
            function Labels(children,distinct=true) 
                if distinct
                    return new(Array{Label}([unique(children)...]),distinct)
                else
                    return new(Array{Label}([children...]),distinct)
                end
            end
        end

        Base.show(l::Labels, io::Core.IO = stdout) = print(io, string(l))
        Base.string(l::Labels) = isempty(l) ? string("∅") : string("{", join(l, ", "), "}")
        
        Base.convert(::Type{Labels}, l::T) where {T<:Array{S} where {S<:String}} = Labels([l...])
        function Base.convert(::Type{Labels}, l::T) where {T<:Array{Any}}
            @assert isempty(l) "Base.convert Labels, unknown non-empty: ($(typeof(l))) : $(string(l))"
            return Labels([],true)
        end
        
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

        show(clocks)
        printlines()
        
        show(value!(clocks,"a"))
        printlines()
        
        show(value!(clocks,"z"))
        printlines()
        
        show(clocks)
        printlines()

        reset!(clocks,[])
        show(clocks)
        printlines()
        
        reset!(clocks,["a","b"])
        show(clocks)
        printlines()
        
        time_step!(clocks, 3)
        show(clocks)
        printlines()
        
        reset!(clocks,["a","b"])
        show(clocks)
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

        g = ConstrainedClocks(e)
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

        c = S((:send, Msg("a", Data(Int)), δ(:tt), [], (:recv, Msg("b", Data(String)), δ(:tt), [] ))) 
        show(c)
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

        a = Choice([
                    (:send, Msg("e", Data(Int)), δ(:tt), []),
                    (:send, Msg("f", Data(Int)), δ(:tt), [], (:send, Msg("g", Data(Int)), δ(:tt), []))
                ])
        b = S(Choice([ 
            (:send, Msg("a", Data(Int)), δ(:tt), []), 
            (:recv, Msg("b", Data(String)), δ(:tt), [], (:send, Msg("c", Data(Int)), δ(:tt), [])),
            (:send, Msg("d", Data(Int)), δ(:tt), [], a) 
            ]))
        show(b)
        printlines()

        show(S(Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], (:send, Msg("a", Data(Int)), δ(:tt), [] ) ))) )
        printlines()

        show(S(Def("a",  Call("a") )) )
        printlines()

        show(S(Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], Call("a") ))) )
        printlines()

        show(S((:send, Msg("a", Data(Int)), δ(:tt), [], Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], Call("a")  ) ))) )
        printlines()

        show(S(([Interaction(:send, Msg("e", Data(Int)),δ(:tt), []  ),Interaction(:send, Msg("f", Data(String)),δ(:tt), []  )])))
        printlines()

        show(S(([(:send, Msg("e", Data(Int)),δ(:tt), []  ),(:send, Msg("f", Data(String)),δ(:tt), []  )])))
        printlines()

        

        println("duality tests:")
        println(string("s: ", string(c)))
        println(string("d: ", string(Dual(c))))
        printlines()
        
        println(string("s: ", string(a)))
        println(string("d: ", string(Dual(a))))
        printlines()
        
        println(string("s: ", string(b)))
        println(string("d: ", string(Dual(b))))
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

        _c = Clocks([("a",1)])
        _v = Valuations(_c)
        _s = S(Choice([(:send, Msg("a", Int), δ(:not,δ(:geq,"x",3)),[], Def("a", (:send, Msg("b", String), δ(:tt), [], Call("a")))),(:recv, Msg("c", Bool), δ(:geq,"y",3),[])]))
        _l = Local(_v,_s)

        show(_l)
        printlines()

        show(System(_l))
        printlines()


        
        _v = Valuations()
        s_b = S(([(:send, Msg("e", Data(Int)),δ(:eq,"x",1), []  ),(:send, Msg("f", Data(String)),δ(:eq,"x",2), []  ),(:recv, Msg("g", Data(Int)),δ(:eq,"x",4), []  ),(:send, Msg("h", Data(String)),δ(:eq,"x",5), []  )]))
        l_b1 = Local(_v,s_b)
        l_b2 = Local(_v,Dual(s_b))
        sys = System(l_b1,l_b2)


        # show(l_b1,:local)
        # printlines()

        # show(Social(l_b1),:social)
        # printlines()

        show(sys)
        printlines()

    end

        
    include("transitions.jl")
    using .Transitions

    if show_transition_tests || show_all_tests
        println("transitions tests:")

        # _c = Clocks([("a",1)])
        # _v = Valuations(_c)
        # _s = S(Choice([(:send, Msg("a", Int), δ(:not,δ(:geq,"x",3)),[], Def("a", (:send, Msg("b", String), δ(:tt), [], Call("a")))),(:recv, Msg("c", Bool), δ(:geq,"y",3),[])]))
        # l_a = Local(_v,_s)
        
        # show(l_a)
        # println()

        # a = LocalSteps(:send,l_a)
        # show(a)
        # printlines()
        # printlines()

        _v = Valuations()
        s_b = S(([(:send, Msg("e", Data(Int)),δ(:eq,"x",1), []  ),(:send, Msg("f", Data(String)),δ(:eq,"x",2), []  ),(:recv, Msg("g", Data(Int)),δ(:eq,"x",4), []  ),(:send, Msg("h", Data(String)),δ(:eq,"x",5), []  )]))
        l_b1 = Local(_v,s_b)
        l_b2 = Local(_v,Dual(s_b))
        sys = System(l_b1,l_b2)


        # show(l_b1,:local)
        # printlines()

        # show(Social(l_b1),:social)
        # printlines()

        show(sys)
        printlines()


        # show(sys)
        # printlines()

        # show(StepDriver())
        # printlines()


        # show(l_b)
        # println()
        # show(EnabledActions(l_b))
        # printlines()

        # show(TimeStep!(l_b.valuations,1))
        # println()
        # show(EnabledActions(l_b))
        # printlines()

        # show(TimeStep!(l_b.valuations,1))
        # println()
        # show(EnabledActions(l_b))
        # printlines()

        # show(TimeStep!(l_b.valuations,1))
        # println()
        # show(EnabledActions(l_b))
        # printlines()

        # show(TimeStep!(l_b.valuations,1))
        # println()
        # show(EnabledActions(l_b))
        # printlines()


    end


end