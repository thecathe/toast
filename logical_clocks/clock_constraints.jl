module ClockConstraints

    import Base.show
    import Base.string

    using ..LogicalClocks

    # signal clock expression
    export δExpr
    const δExpr = Expr

    export δ, supported_constraints
    const supported_constraints = [:tt, :not, :and, :eq, :geq, :deq, :dgeq]

    struct δ
        head::Symbol
        args::T where {T<:Array{Any}}
        expr::δExpr
        clocks::Array{String}

        # empty
        δ() = δ(:tt)

        #
        function δ(head::Symbol,args...)            
            if head==:tt
                @assert length(args)==0 "δ($(string(head))) expects 0 args: ($(length(args))) $(string(args))"

                new(head, [args...], δExpr(:&&,Inf), Array{String}([]))

            elseif head==:not
                @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))"

                @assert args[1] isa δ "δ($(string(head))) expects args of type δ, not: $(string(typeof(args[1])))"

                new(head, [args...], δExpr(:call,[:!, args[1]]), unique(Array{String}([args[1].clocks...])))

            elseif head==:and
                @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))"

                for i ∈ args @assert i isa δ "δ($(string(head))) expects args of type δ, not: $(string(typeof(i)))" end
                
                new(head, [args...], δExpr(:&&, [args[1], args[2]]), unique(Array{String}([args[1].clocks...,args[2].clocks...])))

            elseif head ∈ [:eq,:geq]
                @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))"

                @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not: $(string(typeof(args[1])))"
                
                @assert args[2] isa Num "δ($(string(head))) expects #1 to be Num, not: $(string(typeof(args[1])))"

                new(head, [args...], δExpr(:call, [head==:eq ? :(==) : :(>=), args[1], args[2]]), unique(Array{String}([args[1]])))

            elseif head ∈ [:deq,:dgeq]
                @assert length(args)==3 "δ($(string(head))) expects 3 args: ($(length(args))) $(string(args))"

                @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not: $(string(typeof(args[1])))"
                
                @assert args[2] isa String "δ($(string(head))) expects #1 to be String, not: $(string(typeof(args[1])))"
                
                @assert args[3] isa Num "δ($(string(head))) expects #1 to be Num, not: $(string(typeof(args[1])))"

                new(head, [args...], δExpr(:call, [head==:deq ? :(==) : :(>=), δExpr(:call, [:-, args[1], args[2]]), args[3]]), unique(Array{String}([args[1],args[2]])))

            elseif head==:flatten
                @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))"
                
                @assert args[1] isa δ "δ($(string(head))) expects #1 to be δ, not: $(string(typeof(args[1])))"

                _flat = Flatδ(args[1])
                _clocks = Array{String}([])
                foreach(d -> push!(_clocks, d.clocks...), _flat.children)
                new(head, [_flat.children...], δConjunctify(_flat).child, unique(_clocks))

            else
                @error "δ, unexpected head: $(string(head))"
            end
        end

        Base.show(d::δ, io::Core.IO = stdout) = print(io, string(d))
        Base.show(d::δ, mode::Symbol, io::Core.IO = stdout) = print(io, string(d, mode))

        function Base.string(d::δ, mode::Symbol = :default) 
            if mode==:default
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
                elseif head==:flatten
                    string(join([string(c) for c in d.args], " ∧ "))
                else
                    @error "δ.string, unexpected head: $(string(d.head))"
                end
            else
                @error "δ.string, unexpected mode: $(string(mode))"
            end
        end

    end
    
    #
    # flatten
    #
    struct Flatδ
        children::Array{δ}
        Flatδ(d::δ) = new(flatten(d))
    end

    # flatten constraint tree into conjunctive list
    function flatten(d::δ, neg::Bool = false) 
        if d.head==:and 
            if neg
                Array{δ}([flatten(δ(:not,δ(d.args[1].head,d.args[1].args...)),neg)...,flatten(δ(:not,δ(d.args[2].head,d.args[2].args...)),neg)...]) 
            else 
                Array{δ}([flatten(δ(d.args[1].head,d.args[1].args...),neg)...,flatten(δ(d.args[2].head,d.args[2].args...),neg)...]) 
            end
        elseif d.head==:not
            if neg
                Array{δ}([flatten(δ(:not,δ(d.args[1].head,d.args[1].args...)),!neg)...])
            else 
                Array{δ}([flatten(δ(d.args[1].head,d.args[1].args...),!neg)...])
            end
        else
            if neg
                Array{δ}([δ(:not,d)])
            else 
                Array{δ}([d])
            end
        end
    end

    #
    # conjunctify
    #
    struct δConjunctify
        child::δExpr
        δConjunctify(f::Flatδ) = new(conjunctify(f.children))
    end

    # conjuctify flattned
    function conjunctify(f::T) where {T<:Array{δ}}
        if length(f)>2
            return δExpr(:&&,f[1],conjunctify(f[2:end]))
        elseif length(f)==2
            return δExpr(:&&,f[1],f[2])
        elseif length(f)==1
            return δExpr(:&&,f[1],Inf)
        else
            @error "δ.conjunctify, called with empty list"
        end
    end

    #
    # δ wrapper
    #
    # export δ
    # struct δ <: Constraint 


end