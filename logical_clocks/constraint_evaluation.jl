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
        #
        function δEvaluation!(v::Valuations,d::δ)
            head = d.head
            args = d.args

            # supported_constraints - see ClockConstraints
            @assert head in supported_constraints "δEvaluation!, unexpected head: $(head) ∉ '$(string(supported_constraints))'"

            if head==:tt 
                # :tt => true
                @assert length(args)==0 "δEvaluation! head ($(head)) expects 0 more arguments, not $(length(args)): '$(string(args))'"
                
                _expr = δExpr(:&&, Inf)

            elseif head==:not
                # :not => ¬δ
                @assert length(args)==1 "δEvaluation! head ($(head)) expects 1 more arguments, not $(length(args)): '$(string(args))'"
                
                @assert args[1] isa δ "δEvaluation! head ($(head)) (#1) expects δ types, not: '$(typeof(args[1]))'"
                
                _expr = δExpr(:call, [:!, δEvaluation!(v,args[1]).expr]...)

            elseif head==:and
                # :and => δ₁ ∧ δ₂
                @assert length(args)==2 "δEvaluation! head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                
                @assert args[1] isa δ "δEvaluation! head ($(head)) (#1) expects δ types, not: '$(typeof(args[1]))'"
                
                @assert args[2] isa δ "δEvaluation! head ($(head)) (#2) expects δ types, not: '$(typeof(args[2]))'"
                
                _expr = δExpr(:&&, [δEvaluation!(v,args[1]).expr, δEvaluation!(v,args[2]).expr]...)

            elseif head in [:eq,:geq]
                # :eq => x = n
                # :geq => x ≥ n
                @assert length(args)==2 "δEvaluation! head ($(head)) expects 2 more arguments, not $(length(args)): '$(string(args))'"
                
                _expr = δExpr(:call, [get_call_op(head), Number(ValueOf!(v,args[1]).value), Integer(args[2])]...)

            elseif head in [:deq,:dgeq]
                # :deq => x - y = n
                # :dgeq => x - y ≥ n
                @assert length(args)==3 "δEvaluation! head ($(head)) expects 3 more arguments, not $(length(args)): '$(string(args))'"
                
                _expr = δExpr(:call, [get_call_op(head), δExpr(:call, :-, Number(ValueOf!(v.clocks,args[1]).value), Number(ValueOf!(v.clocks,args[2])).value), Integer(args[3])]...)

            elseif head==:flat
                # :flatten - array contining flattened constraints
                @assert false ∉ [d isa δ for d in args] "δEvaluation! head ($(head)) expects #1 to be Array{δ}, not $(typeof(args)): $(string(args))"
                # @assert length(args)==1 "δEvaluation! head ($(head)) expects 1 more argument, not $(length(args)): '$(string(args))"

                @assert args[1] isa δ "δEvaluation! head ($(head)) expects #1 to be δ, not $(typeof(args[1])): $(string(args[1]))"

                _expr = δExprConjunctify([δEvaluation!(v, c).expr for c in args])
            
            elseif head==:past
                # :past - array of single constraints (:flatten) with each clock geq 0
                @assert false ∉ [d isa δ for d in args] "δEvaluation! head ($(head)) expects #1 to be Array{δ}, not $(typeof(args)): $(string(args))"

                # @info "δEvaluation!:past ($(string(d))), args:\n$(string(join([string(string(x.head), ": ", string(x)) for x in args],"\n\n")))"


                _expr = δExprConjunctify([δEvaluation!(v, c).expr for c in args])

            elseif head==:disjunct
                # :disjunct => for choices, any of these evaluations must hold
                @assert false ∉ [d isa δ for d in args] "δEvaluation! head ($(head)) expects #1 to be Array{δ}, not $(typeof(args)): $(string(args))"

                
                # @info "δEvaluation!:disjunct ($(string(d))), args:\n$(string(join([string(string(x.head), ": ", string(x)) for x in args],"\n\n")))"



                _evals = Array{δEvaluation!}([δEvaluation!(v, c) for c in args])
                _exprs = Array{δExpr}([c.expr for c in _evals])
                _expr = δExprDisjunctify(_exprs)

            else
                @error "δEvaluation!, unexpected head: $(head)"
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


    #
    # conjunctify
    #
    struct δExprConjunctify
        δExprConjunctify(f::T) where {T<:Array{δExpr}} = expr_conjunctify(f)
    end

    # conjuctify flattned
    function expr_conjunctify(f::T) where {T<:Array{δExpr}}
        if length(f)>2
            return δExpr(:&&,f[1],expr_conjunctify(f[2:end]))
        elseif length(f)==2
            return δExpr(:&&,f[1],f[2])
        elseif length(f)==1
            return f[1]
        else
            @error "δExprConjunctify, called with empty list"
        end
    end

    #
    # disjunctify
    #
    struct δExprDisjunctify
        δExprDisjunctify(f::T) where {T<:Array{δExpr}} = expr_disjunctify(f)
    end

    # conjuctify flattned
    function expr_disjunctify(f::T) where {T<:Array{δExpr}}
        if length(f)>2
            return δExpr(:||,f[1],expr_disjunctify(f[2:end]))
        elseif length(f)==2
            return δExpr(:||,f[1],f[2])
        elseif length(f)==1
            return f[1]
        else
            @error "δExprDisjunctify, called with empty list"
        end
    end

end