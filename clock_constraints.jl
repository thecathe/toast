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

    # const δExpr = Expr

    struct δ <: Constraint 
        args::Array{Any}
        function δ(args) 
            supported = [:tt, :not, :and, :eq, :geq, :deq, :dgeq]
            @assert typeof(first(args))==Symbol "δ must start with a symbol in: '$(string(supported))'"
            
            head=first(args)
            @assert head in supported "δ must start with a symbol in: '$(string(supported))'"
            deleteat!(args,1)

            # :and does not use :call
            if head==:and
                @assert length(args) == 2
                Expr(:&&, Constraints(args)...)
            elseif head==:tt 
                @assert length(args) == 0
                Expr(:&&, true)
            elseif head==:not
                @assert length(args) == 1
                Expr(:call, :!, args[1])
            elseif head in [:deq, :dgeq]
                @assert length(args) == 3
                Expr(:call, get_call_op(head), Expr(:call, :-, Label(args[1]), Label(args[2])), Num(args[3]))
            else
                @assert length(args) == 2
                Expr(:call, get_call_op(head), Label(args[1]), Num(args[2]))
            end
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
    Base.string(d::δ) = string(d.child)


    δ(s::Symbol) = δ([s])
    δ(s::Symbol,d::Expr) = δ([s,d])
    δ(s::Symbol,a::Expr,b::Expr) = δ([s,a,b])
    δ(s::Symbol,x::Label,n::Num) = δ([s,x,n])
    δ(s::Symbol,x::Label,y::Label,n::Num) = δ([s,x,y,n])



    δ(:eq, "x", 3)
    δ(:not, δ(:eq, "x", 3))
    δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4))
    δ(:deq, "x", "y", 3)

    
    show(δ(:eq, "x", 3))
    println()
    show(δ(:not, δ(:eq, "x", 3)))
    println()
    show(δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4)))
    println()
    show(δ(:deq, "x", "y", 3))
    println()

    
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