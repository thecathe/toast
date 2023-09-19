module ConstraintEvaluation

    import Base.show
    import Base.string

    using ..LogicalClock
    using ..ClockValuations
    using ..ClockConstraints

    export δEvaluation!

    struct δEvaluation!
        head::Symbol
        args::Array{Any}
        expr::δExpr
        # valuations
        δEvaluation!(v::Valuations,d::δ) = δEvaluation!(v.clocks,d)
        #
        function δEvaluation!(v::T,d::δ) where {T<:Array{Clock}}
            head = d.head
            args = d.args

            # TODO : add (:flatten) and (:past)
            supported_heads = [:tt, :not, :and, :eq, :geq, :deq, :dgeq]
            @assert head in supported_heads "δEvaluation, unexpected head: $(head) ∉ '$(string(supported_heads))'"

            if head==:tt 
                @assert length(args) == 0 "δEval head ($(head)) expects 0 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:&&, Inf)

            elseif head==:not
                @assert length(args) == 1 "δEval head ($(head)) expects 1 more arguments, not $(length(args)): '$(string(args))'"
                @assert args[1] isa δ "δEval head ($(head)) (#1) expects δ types, not: '$(typeof(args[1]))'"
                _expr = δExpr(:call, [:!, δEvaluation!(v,args[1]).expr]...)

            elseif head==:and
                @assert length(args) == 2 "δEval head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                @assert args[1] isa δ "δEval head ($(head)) (#1) expects δ types, not: '$(typeof(args[1]))'"
                @assert args[2] isa δ "δEval head ($(head)) (#2) expects δ types, not: '$(typeof(args[2]))'"
                _expr = δExpr(:&&, [δEvaluation!(v,args[1]).expr, δEvaluation!(v,args[2]).expr]...)

            elseif head in [:eq, :geq]
                @assert length(args) == 2 "δEval head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:call, [get_call_op(head), ValueOf!(v,args[1]).value, Num(args[2])]...)

            elseif head in [:deq, :dgeq]
                @assert length(args) == 3 "δEval head ($(head)) expects 3 more arguments, not $(length(args)): '$(string(args))'"
                _expr = δExpr(:call, [get_call_op(head), δExpr(:call, :-, ValueOf!(v.clocks,args[1]).value, ValueOf!(v.clocks,args[2]).value), Num(args[3])]...)

            else
                @error "δEval, unexpected head: $(head)"
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

    Base.show(e::δEvaluation!, io::Core.IO = stdout) = print(io,string(e))
    Base.show(e::δEvaluation!, mode::Symbol, io::Core.IO = stdout) = print(io,string(e,mode))

    function Base.string(e::δEvaluation!, mode::Symbol=:default)
        if mode==:default
            if e.head!=:not
                return string("(",string(e.expr),") = ", string(eval(e.expr)))
            else
                return string("",string(e.expr)," = ", string(eval(e.expr)))
            end
        else
            @error "δEvaluation!.string, unexpected mode: $(string(mode))"
        end
    end

end