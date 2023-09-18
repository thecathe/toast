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
    using ..Configurations

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
                _expr = δExpr(:call, [:!, Eval(v,args[1]).children[1].expr]...)
            elseif head==:and
                @assert length(args) == 2 "δEval head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                @assert typeof(args[1]) == δ "δEval head ($(head)) (#1) expects δ types, not: '$(typeof(args[1]))'"
                @assert typeof(args[2]) == δ "δEval head ($(head)) (#2) expects δ types, not: '$(typeof(args[2]))'"
                _expr = δExpr(:&&, [Eval(v,args[1]).children[1].expr, Eval(v,args[2]).children[1].expr]...)
            elseif head in [:eq, :geq]
                @assert length(args) == 2 "δEval head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:call, [get_call_op(head), Num(value!(v.clocks,args[1])[1]), Num(args[2])]...)
            elseif head in [:deq, :dgeq]
                @assert length(args) == 3 "δEval head ($(head)) expects 3 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:call, [get_call_op(head), δExpr(:call, :-, Num(value!(v.clocks,args[1])[1]), Num(value!(v.clocks,args[2])[1])), Num(args[3])]...)
            else
                @error "δEval, unknown head: $(head)"
            end

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
    Base.string(d::δEval) = string(if d.head!=:not "(" end, string(d.expr), if d.head!=:not ")" end, " = ", string(eval(d.expr)))


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
        constraints::δ
        clocks::Labels
        children::Evaluations
        result::Bool
        # eval d using valuations of configuration c
        Eval(c::T,d::δ) where {T<:Configuration} = Eval(c.valuations,d)
        # eval d using valuations v
        function Eval(v::Valuations,d::δ)
            _constrained::Labels = ConstrainedClocks(d).labels

            # store result in children
            _children = Evaluations([δEval(v,c) for c in flatten(d)])
            
            if length(_children) == 1
                _result = occursin("true", string(eval(_children[1]))) ? true : false
            else
                _result = ("false" in [string(eval(d.expr)) for d in _children]) ? false : true
            end

            new(v,d,_constrained,_children,_result)
        end
    end
    Base.show(d::Eval, io::Core.IO = stdout)  = print(io, string(d))
    Base.string(d::Eval) = string(string(Clocks([(value!(d.v.clocks, l)[1:2]) for l in d.clocks])), " ⊨ ", string(d.constraints), " = ", string(d.result))

end