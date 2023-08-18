module TOAST

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

    end

    using .General
        
    show_all_tests=false

    show_logical_clock_tests=false
    show_clock_constraints_tests=false
    show_session_type_tests=false
    show_clock_valuations_tests=true
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


        e = δ(:and, δ(:not, δ(:and, δ(:eq, "w", 3), δ(:geq, "x", 4))), δ(:and, δ(:eq, "y", 3), δ(:geq, "z", 4)))   
        show(e)
        println()
        println()

        f = flatten(e)
        show(f)
        println()
        println()

        g = ConstrainedClocks(f)
        show(g)
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

 
    include("clock_valuations.jl")
    using .ClockValuations

    if show_clock_valuations_tests || show_all_tests

        clocks = Clocks([("a",1),("b",2),("c",3)])
        
        a = Valuations(clocks)
        show(a)
        println()
        println()

        show(TimeStep!(a,1))
        println()
        println()

        show(Reset!(a,["b","c","y"]))
        println()
        println()

        show(Value!(a,"z"))
        println()
        println()

        show(TimeStep!(a,3))
        println()
        println()

    end
    
    include("configurations.jl")
    using .Configurations

    if show_configuration_tests || show_all_tests

    end

end