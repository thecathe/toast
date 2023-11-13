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
                # :eq, :geq, :deq, :dgeq, :not, :-
                arg_head = args[1]
                if arg_head==:!
                    string("¬(", string(args[2]), ")")

                elseif arg_head==:(==)
                    string(string(args[2]), "=", string(args[3]))

                elseif arg_head==:(>=)
                    string(string(args[2]), "≥", string(Integer(args[3])))

                elseif arg_head==:-
                    string(string(Number(args[2])), "-", string(Number(args[3])))

                else
                    @error "δExpr.string :call, unexpected head: $(string(arg_head)), $(string(args))"
                end

            elseif head==:(&&)
                if length(args)==2
                    string("", string(args[1]), " ∧ ", string(args[2]), "")
                elseif length(args)==1
                    string("", string(args[1]), "")
                elseif length(args)==0
                    @warn "δExpr.string($(head)), 0 args"
                else
                    @error "δExpr.string, unexpected args: $(string(args)), $(string(args))"
                end

            elseif head==:(||)
                if length(args)==2
                    string("(", string(args[1]), ") ∨ (", string(args[2]), ")")
                elseif length(args)==1
                    string("", string(args[1]), "")
                elseif length(args)==0
                    @warn "δExpr.string($(head)), 0 args"
                else
                    @error "δExpr.string, unexpected args: $(string(args)), $(string(args))"
                end

            else
                @error "δExpr.string, unexpected head: $(string(head)), $(string(args))"
            end

        elseif mode in [:expand,:expand_tail]
            
            if head==:call
                # :eq, :geq, :deq, :dgeq, :not, :-
                arg_head = args[1]
                if arg_head==:!
                    string("¬(", string(args[2]), ")")

                elseif arg_head==:(==)
                    string(string(args[2]), "=", string(args[3]))

                elseif arg_head==:(>=)
                    string(string(args[2]), "≥", string(Integer(args[3])))

                elseif arg_head==:-
                    string(string(Number(args[2])), "-", string(Number(args[3])))

                else
                    @error "δExpr.string :call, unexpected head: $(string(arg_head)), $(string(args))"
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
    const supported_constraints = [:tt, :not, :and, :eq, :geq, :deq, :dgeq, :flatten, :flat, :past, :disjunct, :conjunct]

    struct δ
        head::Symbol
        args::T where {T<:Array{Any}}
        expr::δExpr
        clocks::Array{String}

        # empty
        δ() = δ(:tt)

        #
        function δ(head::Symbol,args...)
            # check if premade, by eval
            if length(args)>0 && args[length(args)]==:eval_ready
                @assert length(args)==4 "δ, eval ready expects 4 args, not $(length(args)): $(string(args))"
                new(head,args[1],args[2],args[3])
            else
                @assert head in supported_constraints "δ, unexpected head: $(head) ∉ '$(string(supported_constraints))'"
                
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
                    # :flatten - restructure δ to be flat conjunction
                    @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))"
                    
                    @assert args[1] isa δ "δ($(string(head))) expects #1 to be δ, not: $(string(typeof(args[1])))"

                    if args[1].head==:flat
                        @warn "δ($(string(head))) should not be used on already flattened δ ($(string(args[1].head)))"
                    end

                    _flat = Flatδ(args[1])
                    _clocks = Array{String}([])
                    foreach(d -> push!(_clocks, d.clocks...), _flat)
                    _expr = δConjunctify(_flat)
                    new(:flat, [_flat...], _expr, unique(_clocks))

                elseif head==:past
                    # :past - flatten and add addition constraints for each constrained clock :geq 0, and 
                    @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))"

                    @assert args[1] isa δ "δ($(string(head))) expects #1 to be δ, not: $(string(typeof(args[1])))"

                    _init_flat = Array{δ}(Flatδ(args[1]))
                    # look for any (:eq, x, n) or (:deq, x, y, n) or (:geq, x, n) or (:dgeq, x, y, n)
                    _past = Array{δ}([Pastδ(f) for f in _init_flat])

                    _clocks = Array{String}([])
                    foreach(d -> push!(_clocks, d.clocks...), _past)

                    _weak_past_children = Array{δ}([_past...])

                    # join flattened 
                    _expr = δConjunctify(_weak_past_children)
                    new(head, _weak_past_children, _expr, unique(_clocks))

                elseif head==:disjunct
                    # :disjunct => list of δ to be disjunctified (for use in choice)
                    @assert length(args)>0 "δ($(string(head))) expects more than 0 args: ($(length(args))) $(string(args))"

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
                    @assert length(args)>0 "δ($(string(head))) expects more than 0 args: ($(length(args))) $(string(args))"

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
                    if head in [:leq,:dleq]
                        @error "δ, head $(string(head)) is not supported"
                    else
                        @error "δ, unexpected head: $(string(head))"
                    end
                end
            end
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
            elseif head==:flat
                string(join([string(c) for c in d.args], " ∧ "))
            elseif head==:past
                string("↓($(string(join([string(c) for c in d.args], " ∧ "))))")
            elseif head==:disjunct
                string("(", string(d.args[1]), ") ∨ (", string(d.args[2]), ")")
                # @warn "δ.string, :disjunct not accounted for yet..."
            elseif head==:conjunct
                string("(", string(d.args[1]), ") ∧ (", string(d.args[2]), ")")
            else
                @error "δ.string, unexpected head: $(string(d.head))"
            end
        else
            @error "δ.string, unexpected mode: $(string(mode))"
        end
    end

    #
    # bounds of δ
    #
    export boundsOf
    # function boundsof(x::String,f::δ)::Array{Tuple{Num,Union{Bool,Num}}}
    #     @assert f.head==:flat "bounds requires flattened δ."
    #     return boundsOf(x,Array{δ}([f.args[1]...]))
    # end
    function boundsOf(x::String,f::Array{δ})::Array{Tuple{Num,Union{Bool,Num}}}#::Tuple{Array{Num},Array{Union{Bool,Num}}}#::Tuple{Num,Union{Bool,Num}}
        # lower_bound = 0
        # upper_bound = true
        lower_bounds = Array{Num}([])
        upper_bounds = Array{Num}([])
        # array of tuples indicating eq (bool indicates neg)
        eq_constraints = Array{Tuple{Bool,Num}}([])
        # always_enabled = false
        # go through each δ and find ones that pertain to x
        for d in f
            if d.head==:tt
                continue
            
            elseif d.head==:not
                child = d.args[1]
                # child = boundsOf(x,Array{δ}([d.args[1]]);neg=!neg)
                # push!(lower_bounds,child[1]...)
                # push!(upper_bounds,child[2]...)
                if child.head==:tt
                    continue
                
                elseif child.head==:not
                    # child = boundsOf(x,Array{δ}([d.args[1]]);neg=!neg)
                    # push!(lower_bounds,child[1]...)
                    # push!(upper_bounds,child[2]...)
                    @error "bounds (child), nested :not. Array{δ} should be flattened."

                elseif child.head==:eq
                    if x ∈ child.clocks
                        @assert child.args[1]==x "bounds (child), expected args[1] to be the clock \"$(x)\", not \"$(string(child.args[1]))\"."
                        push!(eq_constraints,(true,child.args[2]))
                    end
                    
                elseif child.head==:geq
                    if x ∈ child.clocks
                        @assert child.args[1]==x "bounds (child), expected args[1] to be the clock \"$(x)\", not \"$(string(child.args[1]))\"."
                        push!(upper_bounds,child.args[2])
                    end


                elseif child.head ∈ [:deq,:dgeq]
                    @warn "bounds (child), $(string(child.head)) skipped."
                    continue

                else
                    @warn "bounds (child), unhandled d.child.head: $(string(child.head))."
                end

            elseif d.head==:eq
                if x ∈ d.clocks
                    @assert d.args[1]==x "bounds, expected args[1] to be the clock \"$(x)\", not \"$(string(d.args[1]))\"."
                    # push!(lower_bounds,d.args[2])
                    # push!(upper_bounds,d.args[2])
                    push!(eq_constraints,(false,d.args[2]))
                end
                
            elseif d.head==:geq
                if x ∈ d.clocks
                    @assert d.args[1]==x "bounds, expected args[1] to be the clock \"$(x)\", not \"$(string(d.args[1]))\"."
                    push!(lower_bounds,d.args[2])
                end


            elseif d.head ∈ [:deq,:dgeq]
                @warn "bounds, $(string(d.head)) skipped."
                continue

            else
                @warn "bounds, unhandled d.head: $(string(d.head))."
            end
        end
        # lower_bounds = Array{Num}([])
        # upper_bounds = Array{Union{Bool,Num}}([])

        unique!(lower_bounds)
        unique!(upper_bounds)

        paired_bounds = Array{Tuple{Num,Union{Bool,Num}}}([])

        # sort each list
        sort!(lower_bounds)
        sort!(upper_bounds)

        # match each lowerbound to their nearest upper bound
        for lb in lower_bounds
            upper_bound = nothing
            upper_bound_index = nothing
            if length(upper_bounds) > 0
                # for ub in upper_bounds
                for ub_index in range(1, length(upper_bounds))
                    ub = upper_bounds[ub_index]
                    if upper_bound === nothing || ub < upper_bound && lb <= ub
                        upper_bound = ub
                    end
                end

                if upper_bound === nothing
                    # no upperbound given
                    push!(paired_bounds, (lb,true))
                else
                    @assert upper_bound_index !== nothing "bounds, upper_bound !== nothing but no index given."
                    push!(paired_bounds, (lb,upper_bound))
                    deleteat!(upper_bounds, upper_bound_index)
                end
            else
                # no possible upper bounds
                push!(paired_bounds, (lb,true))
            end
        end

        # any remaining upper bounds are paired with 0
        for ub in upper_bounds
            push!(paired_bounds, (0,ub))
        end


        return paired_bounds

        # keep_pairing = true
        # while keep_pairing
        #     # find lowest bound
        #     lowest_bound = nothing
        #     lowest_index = -1
        #     for lb in lower_bounds.
        #         if lowest_bound === nothing || lb < lowest_bound 
        #             lowest_bound = lb
        #             lowest_index = getindex()
        #         end
        #     end
        #     # @assert lowest_bound !== nothing "bounds, lowest_bound is nothing."
        #     if lowest_bound === nothing
        #         lowest_bound = 0
        #     else
        #         deleteat!(lowest_bound,lowest_index)
        #     end

        #     # find lowest upper bound above lowest bound
        #     uppest_bound = nothing
        #     for ub in upper_bounds
        #         if uppest_bound === nothing || ub < uppest_bound && lowest_bound <= ub
        #             uppest_bound = ub
        #         end
        #     end
        #     if uppest_bound === nothing
        #         uppest_bound = true
        #     end
            
        # end

        # return (lower_bound, upper_bound)
    end

    #
    # weak past
    # 
    "Returns the `weak past' of a given δ."
    struct Pastδ
        Pastδ(d::δ) = past(d)
    end

    # convert each constraint to bound to zero
    function past(d::δ, neg::Bool = false)::δ
        if d.head==:eq
            # => (:not (:and, (:not, (:geq, x, n)), (:eq, x, n))))
            # δ(:not, δ(:and, δ(:not, δ(:geq, d.args[1], d.args[2])), δ(:eq, d.args[1], d.args[2])))

            # => (:not (:and, (:not, (:eq, x, n)), (:geq, x, n))))
            δ(:not, δ(:and, δ(:not, δ(:eq, d.args[1], d.args[2])), δ(:geq, d.args[1], d.args[2])))
            
        elseif d.head==:deq
            # => (:not (:and, (:not, (:dgeq, x, y, n)), (:deq, x, y, n))))
            # δ(:not, δ(:and, δ(:not, δ(:dgeq, d.args[1], d.args[2], d.args[3])), δ(:deq, d.args[1], d.args[2], d.args[3])))
            
            # => (:not (:and, (:not, (:dgeq, x, y, n)), (:deq, x, y, n))))
            δ(:not, δ(:and, δ(:not, δ(:deq, d.args[1], d.args[2], d.args[3])), δ(:dgeq, d.args[1], d.args[2], d.args[3])))
            
        elseif d.head==:geq
            # => (:geq, x, 0)
            if neg
                # do not bound to 0 if part of a </≤
                δ(:geq, d.args[1], d.args[2])
            else
                δ(:geq, d.args[1], 0)
            end
            
        elseif d.head==:dgeq
            # => (:dgeq, x, y, 0)
            δ(:dgeq, d.args[1], d.args[2], 0)

        elseif d.head==:not
            # 
            # if neg
            # @info "neg: $(typeof(neg))"
                δ(:not, past(d.args[1], !neg))
            # else
            #     δ(:not, past(d.args[1], true))
            # end
            # δ(:not, past(d.args[1]))


        else
            @warn "δ(:past), unknown flattened head: ($(string(d.head))), args:\n$(string(join(d.args, ",\n")))"
        end
    end
    
    #
    # flatten
    #
    "Returns a flattened δ, no more than 2 deep (for negations)."
    struct Flatδ
        Flatδ(d::δ) = flatten(d)
    end

    # flatten constraint tree into conjunctive list
    function flatten(d::δ, neg::Bool = false)::Array{δ} 
        # @warn "\n\n\nFlatδ should not be used!\n\n\n"
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
        elseif d.head==:disjunct
            @warn "flatten(), head==:disjunct not supported."
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
            @error "δConjunctify, called with empty list"
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