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


    export Constraints

    export δ, δExpr

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
                expr = δExpr(:&&, Inf)
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
    Base.string(d::δ) = string(if d.head!=:not "(" end, string(d.expr), if d.head!=:not ")" end)


    function Base.string(d::δ)
        head = d.head
        if head==:tt
            string("true")
        elseif head==:not
            string("¬(", string(d.args[1]), ")")
        elseif head==:and
            string("", string(d.args[1]), " ∧ ", string(d.args[2]), "")
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
    
    
    mutable struct Constraints <: Constraint
        children::Array{δ}
        Constraints() = Constraints([])
        function Constraints(children)
            new(children)
        end
    end
    Base.show(ds::Constraints, io::Core.IO = stdout) = print(io, string(ds))
    Base.string(ds::Constraints) = string(join([string("",string(d),"") for d in ds], " ∧ "))
    
    Base.push!(ds::Constraints, d::Constraint) = push!(ds.children, d)

    Base.length(ds::Constraints) = length(ds.children)
    Base.isempty(ds::Constraints) = isempty(ds.children)
    Base.getindex(ds::Constraints, i::Int) = getindex(ds.children, i)

    Base.iterate(ds::Constraints) = isempty(ds) ? nothing : (getindex(ds,1), Int(1))
    Base.iterate(ds::Constraints, i::Int) = (i >= length(ds)) ? nothing : (getindex(ds,i+1), i+1)

    
    export flatten

    # flatten constraint tree into conjunctive list
    function flatten(d::δ, neg::Bool = false) 
        if d.head==:and 
            if neg
                Constraints([flatten(δ(:not,δ(d.args[1].head,d.args[1].args...)),neg)...,flatten(δ(:not,δ(d.args[2].head,d.args[2].args...)),neg)...]) 
            else 
                Constraints([flatten(δ(d.args[1].head,d.args[1].args...),neg)...,flatten(δ(d.args[2].head,d.args[2].args...),neg)...]) 
            end
        elseif d.head==:not
            if neg
                Constraints([flatten(δ(:not,δ(d.args[1].head,d.args[1].args...)),!neg)...])
            else 
                Constraints([flatten(δ(d.args[1].head,d.args[1].args...),!neg)...])
            end
        else
            if neg
                Constraints([δ(:not,d)])
            else 
                Constraints([d])
            end
        end
    end

    export ConstrainedClocks

    # return list of relevant clocks in constraint
    struct ConstrainedClocks
        constraint::T where {T<:Constraint}
        flattened::Constraints
        labels::Labels
        function ConstrainedClocks(d::Constraints) 
            _flattened = Constraints()
            for x in d.children
                for y in flatten(x).children
                    push!(_flattened,  y)
                end
            end
            # _flattened = Constraints([_flattened])
            new(d,_flattened,Labels([Label(c) for c in get_labels(_flattened)],true))
        end
        function ConstrainedClocks(d::δ) 
            _flattened = flatten(d)
            new(d,_flattened,Labels([Label(c) for c in get_labels(_flattened)],true))
        end
        
    end
    Base.show(t::ConstrainedClocks, io::Core.IO = stdout) = print(io, string(t))
    Base.string(c::ConstrainedClocks) = string(string(c.constraint), " contrained clocks: ", string(c.labels))


    # get labels in single flattened constraint
    function get_labels(c::Constraints) # TODO fix this circular dependency
        label_builder = Labels([])
        for d in c.children
            if d.head==:not
                @assert length(d.args) == 1 "get_labels expected '($(d.head))' to only have (1) argument, not ($(length(d.args))): $(string(d.args))"
                push!(label_builder, get_labels(Constraints([d.args[1]]))...)
            elseif d.head in [:eq,:geq]
                @assert length(d.args) == 2 "get_labels expected '($(d.head))' to only have (2) arguments, not ($(length(d.args))): $(string(d.args))"
                push!(label_builder, Labels([(d.args[1])])...)
            elseif d.head in [:deq,:dgeq]
                @assert length(d.args) == 3 "get_labels expected '($(d.head))' to only have (3) arguments, not ($(length(d.args))): $(string(d.args))"
                push!(label_builder, Labels([(d.args[1]),(d.args[2])])...)
            else
                @error "get_labels did not expect '($(d.head))', with args ($(length(d.args))): $(string(d.args))"
            end
        end
        return label_builder
    end


end