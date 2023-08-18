module Evaluate

    import Base.show
    import Base.string
    import Base.convert
    import Base.length
    import Base.isempty
    import Base.push!
    import Base.iterate
    import Base.getindex
    
    using ..General
    using ..LogicalClocks
    using ..ClockConstraints
    using ..ClockValuations

    export Eval, δEval

    struct δEval <: Constraint
        head::Symbol
        args::Array{Any}
        expr::δExpr
        function δEval(v::Valuations,d::δ) 
            head = d.head
            args = d.args

            supported = [:tt, :not, :and, :eq, :geq, :deq, :dgeq]            
            @assert head in supported "δEval must start ($(head)) with a symbol in: '$(string(supported))'"

            if head==:tt 
                @assert length(args) == 0 "δEval head ($(head)) expects 0 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:&&, Inf)
            elseif head==:not
                @assert length(args) == 1 "δEval head ($(head)) expects 1 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:call, [:!, Eval(v,args[1]).child[1].expr]...)
            elseif head==:and
                @assert length(args) == 2 "δEval head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                @assert typeof(args[1]) == δ "δEval head ($(head)) (#1) expects δ types, not: '$(typeof(args[1]))'"
                @assert typeof(args[2]) == δ "δEval head ($(head)) (#2) expects δ types, not: '$(typeof(args[2]))'"
                _expr = δExpr(:&&, [Eval(v,args[1]).child[1].expr, Eval(v,args[2]).child[1].expr]...)
            elseif head in [:eq, :geq]
                @assert length(args) == 2 "δEval head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:call, [get_call_op(head), Num(value!(v.clocks,args[1])[1]), Num(args[2])]...)
            elseif head in [:deq, :dgeq]
                @assert length(args) == 3 "δEval head ($(head)) expects 3 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:call, [get_call_op(head), δExpr(:call, :-, Num(value!(v.clocks,args[1])[1]), Num(value!(v.clocks,args[2])[1])), Num(args[3])]...)
            else
                @error "δEval, unknown head: $(head)"
            end

            # show(head)
            # println()
            # println()
            # show(args)
            # println()
            # println()
            # show(_expr)

            new(head,[args...],_expr)
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
    Base.show(d::δEval, io::Core.IO = stdout) = print(io, string(d))
    # Base.string(d::δEval) = string(string(d.expr), " = ")
    Base.string(d::δEval) = string("(", string(d.expr), ") = ", string(eval(d.expr)))


    mutable struct Evaluations 
        children::Array{δEval}
        function Evaluations(children)
            new(children)
        end
    end
    Base.show(ds::Evaluations, io::Core.IO = stdout) = print(io, string(ds))
    Base.string(ds::Evaluations) = string(join([string(d) for d in ds], " ∧ "))
    
    Base.push!(ds::Evaluations, d::δEval) = push!(ds.children, d)

    Base.length(ds::Evaluations) = length(ds.children)
    Base.isempty(ds::Evaluations) = isempty(ds.children)
    Base.getindex(ds::Evaluations, i::Int) = getindex(ds.children, i)

    Base.iterate(ds::Evaluations) = isempty(ds) ? nothing : (getindex(ds,1), Int(1))
    Base.iterate(ds::Evaluations, i::Int) = (i >= length(ds)) ? nothing : (getindex(ds,i+1), i+1)

    Base.convert(::Type{Evaluations}, t::δEval) = Evaluations([t])
    Base.convert(::Type{Evaluations}, t::T) where {T<:Array{δEval}} = Evaluations(t)

    # evaluate constraint against clocks
    struct Eval
        v::Valuations
        δ::δ
        child::Evaluations
        result::Bool
        function Eval(v,d)
            # make sure all clocks are initialised
            # _constrained::Labels = ConstrainedClocks(flatten(_d)).labels
            _constrained::Labels = ConstrainedClocks(d).labels
            foreach(l -> value!(v.clocks,l), _constrained)
            _labels = labels(v.clocks)
            @assert !(false in [l in _labels for l in _constrained])

            _exprs = [δEval(v,c) for c in flatten(d)]

            # show(string(string("_exprs: "), string(_exprs)))
            # println()
            # println()
            
            # store result in child
            _child = Evaluations(_exprs)
            
            # show(string(string("_child: "), string(_child)))
            # println()
            # println()
            # _child = Evaluations([e.expr for e in _exprs])

            if length(_child) == 1
                _result = occursin("true", string(eval(_child[1]))) ? true : false
            else
                _result = ("false" in [string(eval(d.expr)) for d in _child]) ? false : true
            end

            new(v,d,_child,_result)
        end
    end
    Base.show(d::Eval, io::Core.IO = stdout) = print(io, string(d))
    Base.string(d::Eval) = string(string(d.result), " = (", string(d.child), ")")

end