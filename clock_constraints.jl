module ClockConstraints
    export Constraint, C
    
    import Base.show
    import Base.string
    import Base.convert

    import Base.iterate

    import Base.length
    import Base.getindex
    import Base.push!
    import Base.isempty

    using ..General
    using ..LogicalClocks

    abstract type Constraint end

    const Num = T where {T<:Number}

    export Constraints

    mutable struct Constraints <: Constraint
        children::Array{Expr}
        function Constraints(children)
            new(children)
        end
    end
    Base.show(ds::Constraints, io::Core.IO = stdout) = print(io, string(ds))
    Base.string(ds::Constraints) = string(join([string(d) for d in ds], ", "))
    
    Base.push!(ds::Constraints, d::Constraint) = push!(ds.children, d)

    Base.length(ds::Constraints) = length(ds.children)
    Base.isempty(ds::Constraints) = isempty(ds.children)
    Base.getindex(ds::Constraints, i::Int) = getindex(ds.children, i)

    Base.iterate(ds::Constraints) = isempty(ds) ? nothing : (ds[1], Int(1))
    Base.iterate(ds::Constraints, i::Int) = (i >= length(ds)) ? nothing : (ds[i+1], i+1)
    

    export δ

    const δExpr = Expr

    struct δ <: Constraint 
        head::Symbol
        args::Array{Any}
        expr::δExpr
        function δ(head,args...) 
            supported = [:tt, :not, :and, :eq, :geq, :deq, :dgeq]            
            @assert head in supported "δ must start ($(head)) with a symbol in: '$(string(supported))'"

            if head==:tt 
                @assert length(args) == 0 "δ head ($(head)) expects 0 more arguments, not $(length(args)): '$(string(args))'"
                expr = δExpr(:&&, true)
            elseif head==:not
                @assert length(args) == 1 "δ head ($(head)) expects 1 more arguments, not $(length(args)): '$(string(args))'"
                expr = δExpr(:call, [:!, args[1]])
            elseif head==:and
                @assert length(args) == 2 "δ head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                @assert typeof(args[1]) == δ "δ head ($(head)) (#1) expects δ types, not: '$(typeof(args[1]))'"
                @assert typeof(args[2]) == δ "δ head ($(head)) (#2) expects δ types, not: '$(typeof(args[2]))'"
                expr = δExpr(:&&, [args[1], args[2]]...)
            elseif head in [:eq, :geq]
                @assert length(args) == 2 "δ head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                expr = δExpr(:call, [get_call_op(head), Label(args[1]), Num(args[2])])
            elseif head in [:deq, :dgeq]
                @assert length(args) == 3 "δ head ($(head)) expects 3 more arguments, not $(length(args)): '$(string(args))'"
                expr = δExpr(:call, [get_call_op(head), δExpr(:call, :-, Label(args[1]), Label(args[2])), Num(args[3])])
            else
                @error "δ, unknown head: $(head)"
            end

            new(head,[args...],expr)
        end

        function get_call_op(head::Symbol)
            if head==:eq
                return :(==)
            elseif head==:geq
                return :(>=)
            elseif head==:deq
                return :(==)
            elseif head==:dgeq
                return :(>=)
            end
        end
    end
    Base.show(d::δ, io::Core.IO = stdout) = print(io, string(d))

    function Base.string(d::δ)
        head = d.head

        if head==:tt
            string("true")
        elseif head==:not
            string("¬(", string(d.args[1]), ")")
        elseif head==:and
            string("(", string(d.args[1]), ") ∧ (", string(d.args[2]), ")")
        elseif head==:eq
            string(string(d.args[1]), "=", string(d.args[2]))
        elseif head==:geq
            string(string(d.args[1]), "≥", string(d.args[2]))
        elseif head==:deq
            string(string(d.args[1]), "-", string(d.args[2]), "=", string(d.args[3]))
        elseif head==:dgeq
            string(string(d.args[1]), "-", string(d.args[2]), "≥", string(d.args[3]))
        else
            string("unknown head: ", string(d.head))
        end
    end

    # for sorting out δ args
    # Base.convert(::Type{Array{Any}}, t::T) where {T<:Tuple} = [t...]

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


    # Base.string(d::δExpr) = string(d.head, d.args...)

    # function Base.string(s::Symbol) 
    #     @assert s==:tt
    #     string("true")
    # end

    # function Base.string(s::Symbol, d::δExpr) 
    #     @assert s==:not
    #     string("¬", string(d))
    # end

    # function Base.string(s::Symbol, a::δExpr, b::δExpr) 
    #     @assert s==:and 
    #     string(string(a), " ∧ ", string(b))
    # end

    # function Base.string(s::Symbol, x::Label, n::Num) 
    #     @assert s in [:eq, :geq]
    #     if s == :eq
    #         string(string(x), "=", string(n))
    #     else
    #         string(string(x), "≥", string(n))
    #     end
    # end

    # function Base.string(s::Symbol, x::Label, y::Label) 
    #     @assert s in [:deq, :dgeq]
    #     if s == :eq
    #         string(string(x), "=", string(n))
    #     else
    #         string(string(x), "≥", string(n))
    #     end
    # end

    # δ(s::Symbol) = δ(s)
    # δ(s::Symbol,d::Expr) = δ(s,d)
    # δ(s::Symbol,a::Expr,b::Expr) = δ(s,[a,b])
    # δ(s::Symbol,x::Label,n::Num) = δ(s,[x,n])
    # δ(s::Symbol,x::Label,y::Label,n::Num) = δ(s,[x,y,n])



    # δ(:eq, "x", 3)
    # δ(:not, δ(:eq, "x", 3))
    # δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4))
    # δ(:deq, "x", "y", 3)

    

    
    # show(eval(δ(:eq, "x", 3)))
    # println()
    # show(eval(δ(:not, δ(:eq, "x", 3))))
    # println()
    # show(eval(δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4))))
    # println()
    # show(eval(δ(:deq, "x", "y", 3)))
    # println()
    # println()


    # # Expr(:eq, x, n)

    # # Expr(:eq, x::Label, n::ConstraintConstant) <: Constraint = 
    # Base.convert(::Type{Expr}, d::T) where {T<:Tuple{Symbol,Label,Num}} = δExpr(d[1],d[2],d[3])
    
    # test = δ( (:eq, "a", 3) )
    # show(test)


    # Base.eval(d::δ) = eval(d.child)
    # function Base.eval(d::δExpr) 

    # end

    # δExpr(:eq, x::Label, n::Num) = 





    # flatten constraint tree into conjunctive list
    function flatten(d::δ)
        return Constraints([])
    end
end