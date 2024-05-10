module ClockConstraints

    import Base.show
    import Base.string

    using ..LogicalClocks

    # signal clock expression
    export δExpr, δConjunctify
    const δExpr = Expr

    Base.show(d::δExpr, io::Core.IO = stdout) = print(io, string(d))
    Base.show(d::δExpr, mode::Symbol, io::Core.IO = stdout) = print(io, string(d, mode))

    function Base.string(d::δExpr, mode::Symbol=:default)
        head = d.head
        args = d.args
        if mode==:default
            # if head==:tt
            #     string("true")
            if head==:call
                # :eq, :geq, :deq, :dgtr, :not, :-
                arg_head = args[1]
                if arg_head==:!
                    string("¬(", string(args[2]), ")")

                elseif arg_head==:(==)
                    string(string(args[2]), "=", string(args[3]))

                elseif arg_head==:(>=)
                    string(string(args[2]), "≥", string(Integer(args[3])))

                elseif arg_head==:(>)
                    string(string(args[2]), ">", string(Integer(args[3])))

                elseif arg_head==:(<=)
                    string(string(args[2]), "≤", string(Integer(args[3])))

                elseif arg_head==:(<)
                    string(string(args[2]), "<", string(Integer(args[3])))

                elseif arg_head==:-
                    string(string(Number(args[2])), "-", string(Number(args[3])))

                else
                    @error "δExpr.string :call, unexpected head '$(string(arg_head))': '$(string(join([string(a) for a in args])))'."
                end

            elseif head==:(&&)
                if length(args)==2
                    string("", string(args[1]), " ∧ ", string(args[2]), "")
                elseif length(args)==1
                    string("", string(args[1]), "")
                elseif length(args)==0
                    @warn "δExpr.string($(head)), 0 args"
                else
                    @error "δExpr.string, unexpected args: '$(string(args))', '$(string(args))'."
                end

            elseif head==:(||)
                if length(args)==2
                    string("(", string(args[1]), ") ∨ (", string(args[2]), ")")
                elseif length(args)==1
                    string("", string(args[1]), "")
                elseif length(args)==0
                    @warn "δExpr.string($(head)), 0 args"
                else
                    @error "δExpr.string, unexpected args: '$(string(args))', '$(string(args))'."
                end

            else
                @error "δExpr.string, unexpected head: '$(string(head))', '$(string(args))'."
            end

        elseif mode in [:expand,:expand_tail]
            
            if head==:call
                # :eq, :geq, :deq, :dgtr, :not, :-
                arg_head = args[1]
                if arg_head==:!
                    string("¬(", string(args[2]), ")")

                elseif arg_head==:(==)
                    string(string(args[2]), "=", string(args[3]))

                elseif arg_head==:(>=)
                    string(string(args[2]), "≥", string(Integer(args[3])))

                elseif arg_head==:(>)
                    string(string(args[2]), ">", string(Integer(args[3])))

                elseif arg_head==:(<=)
                    string(string(args[2]), "≤", string(Integer(args[3])))

                elseif arg_head==:(<)
                    string(string(args[2]), "<", string(Integer(args[3])))

                elseif arg_head==:-
                    string(string(Number(args[2])), "-", string(Number(args[3])))

                else
                    @error "δExpr.string :call, unexpected head $(string(arg_head)): $(string(join([string(a) for a in args])))."
                end

            elseif head==:(&&)
                if length(args)==2
                    string("", string(args[1]), " ∧ ", string(args[2],mode), "")
                elseif length(args)==1
                    string("", string(args[1]), "")
                elseif length(args)==0
                    @warn "δExpr.string($(head)), 0 args"
                else
                    @error "δExpr.string, unexpected args: $(string(args)), $(string(args))"
                end

            elseif head==:(||)
                if length(args)==2
                    string("(", string(args[1],mode), ") == $(string(eval(args[1])))\n ∨ ", string(args[2],mode), args[2].head!=:(||) ? " == $(string(eval(args[2])))" : "")
                elseif length(args)==1
                    string("(", string(args[1],:expand_tail), ") == $(string(eval(args[1])))")
                elseif length(args)==0
                    @warn "δExpr.string($(head)), 0 args"
                else
                    @error "δExpr.string, unexpected args: $(string(args)), $(string(args))"
                end

            else
                @error "δExpr.string, unexpected head: $(string(head)), $(string(args))"
            end


        else
            @error "δExpr.string, unexpected mode: $(mode), $(string(args))"
        end
    end

    export δ, supported_constraints
    const supported_constraints = [:tt, :not, :and, :eq, :geq, :deq, :dgtr, :or, :leq, :les, :gtr, :ff]
    const supported_formats = [:disjunct, :conjunct]

    mutable struct δ
        head::Symbol
        args::T where {T<:Array{Any}}
        expr::δExpr
        clocks::Array{String}

        # keep track of each eval made
        evals::Array{ν}

        # empty
        δ() = δ(:tt)

        #
        function δ(head::Symbol,args...)
            # check if premade, by eval
            # if length(args)>0 && args[length(args)]==:eval_ready
            #     @assert length(args)==4 "δ, eval ready expects 4 args, not $(length(args)): $(string(args))."
            #     new(head,args[1],args[2],args[3])
            # else
            @assert head in [supported_constraints...,supported_formats...] "δ, unexpected head: $(head) ∉ '$(string(supported_constraints))'."
            
            if head==:tt
                @assert length(args)==0 "δ($(string(head))) expects 0 args: ($(length(args))) $(string(args))."

                new(head, [args...], δExpr(:&&,true), Array{String}([]), Array{ν}([]))

            elseif head==:ff
                @assert length(args)==0 "δ($(string(head))) expects 0 args: ($(length(args))) $(string(args))."

                new(head, [args...], δExpr(:&&,false), Array{String}([]), Array{ν}([]))

            elseif head==:not
                @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))."

                @assert args[1] isa δ "δ($(string(head))) expects args of type δ, not: $(string(typeof(args[1])))."

                new(head, [args...], δExpr(:call,[:!, args[1]]), unique(Array{String}([args[1].clocks...])), Array{ν}([]))

            elseif head==:and
                @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))."

                for i ∈ args @assert i isa δ "δ($(string(head))) expects args of type δ, not: $(string(typeof(i)))." end
                
                new(head, [args...], δExpr(:&&, [args[1], args[2]]), unique(Array{String}([args[1].clocks...,args[2].clocks...])), Array{ν}([]))

            elseif head ∈ [:eq,:geq]
                @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))."

                @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not $(string(typeof(args[1]))): $(string(args[1]))."
                
                @assert args[2] isa Num "δ($(string(head))) expects #2 to be Num, not $(string(typeof(args[2]))): $(string(args[2]))."

                new(head, [args...], δExpr(:call, [head==:eq ? :(==) : :(>=), args[1], args[2]]), unique(Array{String}([args[1]])), Array{ν}([]))

            # the special cases (converted to other cases)
            elseif head ∈ [:or,:leq,:les,:gtr]
                if head==:or
                    @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))."

                    for i ∈ args @assert i isa δ "δ($(string(head))) expects args of type δ, not: $(string(typeof(i)))." end

                    # return δ(:not,δ(:and,δ(:not,args[1]),δ(:not,args[2])))
                    new(head, [args...], δExpr(:||, [args[1], args[2]]), unique(Array{String}([args[1].clocks...,args[2].clocks...])), Array{ν}([]))

                elseif head==:leq
                    @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))."

                    @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not $(string(typeof(args[1]))): $(string(args[1]))."
                    
                    @assert args[2] isa Num "δ($(string(head))) expects #2 to be Num, not $(string(typeof(args[2]))): $(string(args[2]))."

                    # return δ(:or,δ(:not,δ(:geq,args[1],args[2])),δ(:eq,args[1],args[2]))
                    new(head, [args...], δExpr(:call, [:(<=), args[1], args[2]]), unique(Array{String}([args[1]])), Array{ν}([]))

                elseif head==:les
                    @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))."

                    @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not $(string(typeof(args[1]))): $(string(args[1]))."
                    
                    @assert args[2] isa Num "δ($(string(head))) expects #2 to be Num, not $(string(typeof(args[2]))): $(string(args[2]))."

                    # return δ(:not,δ(:geq,args[1],args[2]))
                    new(head, [args...], δExpr(:call, [:(<), args[1], args[2]]), unique(Array{String}([args[1]])), Array{ν}([]))

                elseif head==:gtr
                    @assert length(args)==2 "δ($(string(head))) expects 2 args: ($(length(args))) $(string(args))."

                    @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not $(string(typeof(args[1]))): $(string(args[1]))."
                    
                    @assert args[2] isa Num "δ($(string(head))) expects #2 to be Num, not $(string(typeof(args[2]))): $(string(args[2]))."

                    # return δ(:and,δ(:geq,args[1],args[2]),δ(:not,δ(:eq,args[1],args[2])))
                    new(head, [args...], δExpr(:call, [:(>), args[1], args[2]]), unique(Array{String}([args[1]])), Array{ν}([]))

                end

            elseif head ∈ [:deq,:dgtr]
                @assert length(args)==3 "δ($(string(head))) expects 3 args: ($(length(args))) $(string(args))."

                @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not: $(string(typeof(args[1])))."
                
                @assert args[2] isa String "δ($(string(head))) expects #1 to be String, not: $(string(typeof(args[1])))."
                
                @assert args[3] isa Num "δ($(string(head))) expects #1 to be Num, not: $(string(typeof(args[1])))."

                new(head, [args...], δExpr(:call, [head==:deq ? :(==) : :(>), δExpr(:call, [:-, args[1], args[2]]), args[3]]), unique(Array{String}([args[1],args[2]])), Array{ν}([]))

            elseif head==:disjunct
                # :disjunct => list of δ to be disjunctified (for use in choice)
                @assert length(args)>0 "δ($(string(head))) expects more than 0 args: ($(length(args))) $(string(args))."

                # flatten each δ
                _flats = Array{δ}([δ(:flatten, d) for d in args[1]])

                # get clocks from each δ (flattened)
                _clocks = Array{String}([])
                foreach(d -> push!(_clocks, d.clocks...), _flats)

                # join flattened δ with disjuncts 
                _expr = δDisjunctify(_flats)
                new(head, _flats, _expr, unique(_clocks))

            elseif head==:conjunct
                # :conjunct => list of δ to be conjunctified (for use in receive urgency)
                @assert length(args)>0 "δ($(string(head))) expects more than 0 args: ($(length(args))) $(string(args))."

                # flatten each δ
                # _flats = Array{δ}([δ(:flatten, d) for d in args[1]])
                _flats = Array{δ}([args...])

                # get clocks from each δ (flattened)
                _clocks = Array{String}([])
                foreach(d -> push!(_clocks, d.clocks...), _flats)

                # join flattened δ with disjuncts 
                _expr = δConjunctify(_flats)
                new(head, _flats, _expr, unique(_clocks))

            else
                if head==:dleq
                    @error "δ, head $(string(head)) is not supported."
                else
                    @error "δ, unexpected head: $(string(head))."
                end
            end
            # end
        end
    end
    
    Base.show(d::δ, io::Core.IO = stdout) = print(io, string(d))
    Base.show(d::δ, mode::Symbol, io::Core.IO = stdout) = print(io, string(d, mode))

    function Base.string(d::δ, mode::Symbol = :default) 
        if mode==:default
            head = d.head
            if head==:tt
                string("true")
            elseif head==:ff
                string("false")
            elseif head==:not
                string("¬(", string(d.args[1]), ")")
            elseif head==:and
                string("(", string(d.args[1]), " ∧ ", string(d.args[2]), ")")
            elseif head==:or
                string("", string(d.args[1]), " ∨ ", string(d.args[2]), "")
            elseif head==:eq
                string(string(d.args[1]), "=", string(d.args[2]))
            elseif head==:geq
                string(string(d.args[1]), "≥", string(d.args[2]))
            elseif head==:gtr
                string(string(d.args[1]), ">", string(d.args[2]))
            elseif head==:leq
                string(string(d.args[1]), "≤", string(d.args[2]))
            elseif head==:les
                string(string(d.args[1]), "<", string(d.args[2]))
            elseif head==:deq
                string(string(d.args[1]), "-", string(d.args[2]), "=", string(d.args[3]))
            elseif head==:dgtr
                string(string(d.args[1]), "-", string(d.args[2]), ">", string(d.args[3]))
            elseif head==:disjunct
                string("(", string(d.args[1]), ") ∨ (", string(d.args[2]), ")")
                # @warn "δ.string, :disjunct not accounted for yet..."
            elseif head==:conjunct
                string("(", string(d.args[1]), ") ∧ (", string(d.args[2]), ")")
            else
                @error "δ.string, unexpected head: $(string(d.head))."
            end
        elseif mode==:norm
            string(normaliseδ(d))
        else
            @error "δ.string, unexpected mode: $(string(mode))."
        end
    end

    #
    # conjunctify
    #
    "Returns a single δ comprised of the conjunction of all in the given array of δ."
    struct δConjunctify
        δConjunctify(f::T) where {T<:Array{δ}} = conjunctify(f)
    end

    # conjuctify flattned
    function conjunctify(f::T)::δExpr where {T<:Array{δ}}
        if length(f)>2
            return δExpr(:&&,f[1],conjunctify(f[2:end]))
        elseif length(f)==2
            return δExpr(:&&,f[1],f[2])
        elseif length(f)==1
            # return f[1]
            return δExpr(:&&,f[1])
        else
            @error "δConjunctify, called with empty list."
        end
    end

    #
    # disjunctify
    #
    "Returns a single δ comprised of the discjunction of all in the given array of δ."
    struct δDisjunctify
        δDisjunctify(f::T) where {T<:Array{δ}} = disjunctify(f)
    end

    # disjunctify flattned
    function disjunctify(f::T)::δExpr where {T<:Array{δ}}
        if length(f)>2
            return δExpr(:||,f[1],disjunctify(f[2:end]))
        elseif length(f)==2
            return δExpr(:||,f[1],f[2])
        elseif length(f)==1
            # return f[1]
            return δExpr(:||,f[1])
        else
            @error "δConjunctify, called with empty list"
        end
    end

end