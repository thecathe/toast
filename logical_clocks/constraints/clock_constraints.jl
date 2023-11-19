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
    const supported_constraints = [:tt, :not, :and, :eq, :geq, :deq, :dgeq, :or, :leq, :les, :gtr]
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

                new(head, [args...], δExpr(:&&,Inf), Array{String}([]), Array{ν}([]))

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

            elseif head ∈ [:deq,:dgeq]
                @assert length(args)==3 "δ($(string(head))) expects 3 args: ($(length(args))) $(string(args))."

                @assert args[1] isa String "δ($(string(head))) expects #1 to be String, not: $(string(typeof(args[1])))."
                
                @assert args[2] isa String "δ($(string(head))) expects #1 to be String, not: $(string(typeof(args[1])))."
                
                @assert args[3] isa Num "δ($(string(head))) expects #1 to be Num, not: $(string(typeof(args[1])))."

                new(head, [args...], δExpr(:call, [head==:deq ? :(==) : :(>=), δExpr(:call, [:-, args[1], args[2]]), args[3]]), unique(Array{String}([args[1],args[2]])), Array{ν}([]))

            # elseif head==:flatten
            #     # :flatten - restructure δ to be flat conjunction
            #     @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))."
                
            #     @assert args[1] isa δ "δ($(string(head))) expects #1 to be δ, not: $(string(typeof(args[1])))."

            #     if args[1].head==:flat
            #         @warn "δ($(string(head))) should not be used on already flattened δ ($(string(args[1].head)))."
            #     end

            #     _flat = Flatδ(args[1])
            #     _clocks = Array{String}([])
            #     foreach(d -> push!(_clocks, d.clocks...), _flat)
            #     _expr = δConjunctify(_flat)
            #     new(:flat, [_flat...], _expr, unique(_clocks))

            # elseif head==:past && false
            #     # :past - flatten and add addition constraints for each constrained clock :geq 0, and 
            #     @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))."

            #     @assert args[1] isa δ "δ($(string(head))) expects #1 to be δ, not: $(string(typeof(args[1])))."

            #     _init_flat = Array{δ}(Flatδ(args[1]))
            #     # _init_flat = init_flat[1]
            #     # look for any (:eq, x, n) or (:deq, x, y, n) or (:geq, x, n) or (:dgeq, x, y, n)
            #     _init_past = Array{δ}([Pastδ(f) for f in _init_flat])
            #     _past = Array{δ}([])
            #     foreach(p -> push!(_past, Flatδ(p)...), _init_past)
            #     # _past = Array{δ}([])
            #     # for f in _init_flat
            #     #     if 
            #     # end

            #     _clocks = Array{String}([])
            #     foreach(d -> push!(_clocks, d.clocks...), _past)
            #     unique!(_clocks)

            #     # @assert !isempty(_clocks) "δ($(string(head))), no clocks found in: $(string(join([string("($(string(p)))") for p in _past], ", ")))."

            #     @debug "δ($(string(head))), flats:...\n$(string(join([string(f) for f in _init_flat], "\n")))."
            #     @debug "δ($(string(head))), clocks: $(string(_clocks))."
            #     @debug "δ($(string(head))), pasts:...\n$(string(join([string(p) for p in _past], "\n")))."

            #     # now, find greatest constraint on each clock to keep
            #     _weak_past_children = Array{δ}([])
            #     # _weak_past_children = Array{δ}([_past...])
            #     # @info "δ($(string(head))), starting clocks."
            #     for c in _clocks
            #         # @info "δ($(string(head))), A clock $(c)."
            #         clock_highest_bound = nothing
            #         for p in _past
            #             # @info "δ($(string(head))), $(string(p.head)): $(string(p))." 
            #             # if :tt found, then any value of this clock holds
            #             if p.head==:tt
            #                 clock_highest_bound = true
            #                 break
                        
            #             elseif p.head ∈ [:deq,:dgeq]
            #                 @warn "δ($(string(head))), $(string(p.head)) skipped."
                        
            #             elseif p.head==:not
            #                 child = p.args[1]
            #                 if child.head==:tt
            #                     clock_highest_bound = true
            #                     break

            #                 elseif child.head ∈ [:deq,:dgeq]
            #                     @warn "δ($(string(head))) (child), $(string(child.head)) skipped."

            #                 elseif child.head==:not
            #                     @error "δ($(string(head))) (child), should not have nested $(string(child.head))."
                            
            #                 elseif child.head ∈ [:eq,:geq]
            #                     if c in child.clocks && (clock_highest_bound === nothing || clock_highest_bound<child.args[2])
            #                         @assert child.args[2] isa Num "δ($(string(child.head))) expects #2 to be Num, not $(string(typeof(child.args[2]))): $(string(child.args[2]))."
            #                         clock_highest_bound = child.args[2]
            #                     # else
            #                     #     @info "δ($(string(head))) (child, $(string(child.head))), $(string(child)) is not higherbound than $(string(clock_highest_bound))."
            #                     end
                            
            #                 else
            #                     @warn "δ($(string(child.head))) (child) not accounted for: $(string(child))."
            #                 end
                        
            #             elseif p.head ∈ [:eq,:geq]
            #                 if c in p.clocks 
            #                     # check if past :geq (x ≥ 0)
            #                     if p.head==:geq && p.args[2]==0
            #                         clock_highest_bound = true
            #                         break

            #                     elseif (clock_highest_bound === nothing || clock_highest_bound<p.args[2])
            #                         @assert p.args[2] isa Num "δ($(string(p.head))) expects #2 to be Num, not $(string(typeof(p.args[2]))): $(string(p.args[2]))."
            #                         clock_highest_bound = p.args[2]
            #                     end
            #                 # else
            #                 #     @info "δ($(string(head))) ($(string(p.head))), $(string(p)) is not higherbound than $(string(clock_highest_bound))."
            #                 end
            #             else
            #                 @warn "δ($(string(p.head))) not accounted for: $(string(p))."
            #             end
            #         end
            #         # @info "δ($(string(head))), B clock $(c)."
            #         @debug "δ($(string(head))), clock_highest_bound isa $(string(typeof(clock_highest_bound))): $(string(clock_highest_bound))."
            #         # if not nothing, enforce upper bound
            #         if clock_highest_bound !== nothing
            #             if clock_highest_bound isa Num
            #                 push!(_weak_past_children, δ(:not,δ(:geq,c,clock_highest_bound)))
            #                 # @info "δ($(string(head))), $(c) upperbound by $(clock_highest_bound)."
            #             elseif clock_highest_bound isa Bool
            #                 @assert clock_highest_bound "δ($(string(head))), found :tt, but expect this to be true."
            #                 # @info "δ($(string(head))), $(c) can have any value."
            #                 push!(_weak_past_children, δ(:geq, c, 0))
            #             else
            #                 @warn "δ($(string(head))), unexpected clock_highest_bound isa $(string(typeof(clock_highest_bound))): $(string(clock_highest_bound))."
            #             end
            #         else
            #             @warn "δ($(string(head))), no highest clock bound found for $(c) in $(string(join([string(p) for p in _past], ", ")))."
            #         end
            #     end
            #     # @info "δ($(string(head))), finished clocks."

            #     if isempty(_weak_past_children)
            #         @warn "δ($(string(head)), $(string(join([string("($(string(_d)))") for _d in _init_flat], ", ")))), expected _weak_past_children ($(string(join([string(c) for c in _clocks], ", ")))) to be non-empty.\npast: $(string(join([string(p) for p in _past], ", ")))."
            #     end

            #     # join flattened 
            #     _expr = δConjunctify(_weak_past_children)
            #     new(head, _weak_past_children, _expr, unique(_clocks))

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
            elseif head==:dgeq
                string(string(d.args[1]), "-", string(d.args[2]), "≥", string(d.args[3]))
            # elseif head==:flat
            #     string(join([string(c) for c in d.args], " ∧ "))
            # elseif head==:past
            #     string("↓($(string(join([string(c) for c in d.args], " ∧ "))))")
            elseif head==:disjunct
                string("(", string(d.args[1]), ") ∨ (", string(d.args[2]), ")")
                # @warn "δ.string, :disjunct not accounted for yet..."
            elseif head==:conjunct
                string("(", string(d.args[1]), ") ∧ (", string(d.args[2]), ")")
            else
                @error "δ.string, unexpected head: $(string(d.head))."
            end
        else
            @error "δ.string, unexpected mode: $(string(mode))."
        end
    end

    # #
    # # weak past
    # # 
    # "Returns the `weak past' of a given δ."
    # struct Pastδ
    #     Pastδ(d::δ) = past(d)
    # end

    # # convert each constraint to bound to zero
    # function past(d::δ, neg::Bool = false)::δ
    #     if d.head==:eq
    #         return δ(:not, δ(:and, 
    #             δ(:geq, d.args[1], d.args[2]),
    #             δ(:not, δ(:eq, d.args[1], d.args[2])), 
    #         ))
    #         # return δ(:not, δ(:and, δ(:not, δ(:eq, d.args[1], d.args[2])), δ(:geq, d.args[1], d.args[2])))
            
    #     # elseif d.head==:deq
    #     #     # => (:not (:and, (:not, (:dgeq, x, y, n)), (:deq, x, y, n))))
    #     #     # δ(:not, δ(:and, δ(:not, δ(:dgeq, d.args[1], d.args[2], d.args[3])), δ(:deq, d.args[1], d.args[2], d.args[3])))
            
    #     #     # => (:not (:and, (:not, (:dgeq, x, y, n)), (:deq, x, y, n))))
    #     #     δ(:not, δ(:and, δ(:not, δ(:deq, d.args[1], d.args[2], d.args[3])), δ(:dgeq, d.args[1], d.args[2], d.args[3])))
            
    #     elseif d.head==:geq
    #         # => (:geq, x, 0)
    #         if neg
    #             # if neg, is lessthan. past of < is the same
    #             # return δ(:not, δ(:and, δ(:not, δ(:eq, d.args[1], d.args[2])), δ(:geq, d.args[1], d.args[2])))
    #             # return δ(:geq, d.args[1], d.args[2])
    #             return d
    #         else
    #             # if not neg, then is always true
    #             # return δ(:tt)
    #             return δ(:geq, d.args[1], 0)
    #         end
            
    #     # elseif d.head==:dgeq
    #     #     # => (:dgeq, x, y, 0)
    #     #     δ(:dgeq, d.args[1], d.args[2], 0)

    #     elseif d.head==:not
    #         # 
    #         # if neg
    #         # @info "neg: $(typeof(neg))"
    #             return δ(:not, past(d.args[1], !neg))
    #         # else
    #         #     δ(:not, past(d.args[1], true))
    #         # end
    #         # δ(:not, past(d.args[1]))

    #     elseif d.head ∈ [:deq,:dgeq]
    #         return d

    #     else
    #         @warn "δ(:past), unknown flattened head: ($(string(d.head))), args:\n$(string(join(d.args, ",\n")))"
    #     end
    # end
    
    # #
    # # flatten
    # #
    # "Returns a flattened δ, no more than 2 deep (for negations)."
    # struct Flatδ
    #     function Flatδ(d::δ) 
    #         flat =  flatten(d)

    #         if flat[2]%2>0
    #             return Array{δ}([δ(:not, f) for f in flat[1]])
    #         else
    #             return Array{δ}([flat[1]...])
    #         end
    #     end
    # end

    # # flatten constraint tree into conjunctive list
    # function flatten(d::δ; neg::Int64 = 0)::Tuple{Array{δ},Int64}
    # # function flatten(d::δ; neg::Bool = false)::Array{δ} 
    #     # @warn "\n\n\nFlatδ should not be used!\n\n\n"
    #     #
    #     #
    #     #
    #     # ! this needs redoing, :not must be wrapped arond the outside of each return of flatten
    #     #
    #     if d.head==:and 
    #         lhs = δ(d.args[1].head,d.args[1].args...)
    #         rhs = δ(d.args[2].head,d.args[2].args...)

    #         f_lhs = flatten(lhs;neg=neg)
    #         f_rhs = flatten(rhs;neg=neg)

    #         # @info "Flattening (neg=$(neg)): $(string(d))."

    #         # return (Array{δ}([
    #         #     [(f_lhs[2]%2>0) ? [δ(:not,f) for f in f_lhs[1]]... : f_lhs...]...,
    #         #     [(f_rhs[2]%2>0) ? [δ(:not,f) for f in f_rhs[1]]... : f_rhs...]...
    #         # ]),neg)

    #         if f_lhs[2]%2>0
    #             a_lhs = Array{δ}([[δ(:not,f) for f in f_lhs[1]]...])
    #         else
    #             a_lhs = Array{δ}([f_lhs[1]...])
    #         end

    #         if f_rhs[2]%2>0
    #             a_rhs = Array{δ}([[δ(:not,f) for f in f_rhs[1]]...])
    #         else
    #             a_rhs = Array{δ}([f_rhs[1]...])
    #         end

    #         # @info "Flattened (neg=$(neg)): $(string(d)),
    #         #     lhs: $(string(join([string(l) for l in a_lhs],", "))),
    #         #     rhs: $(string(join([string(r) for r in a_rhs],", ")))."

    #         return (Array{δ}([a_lhs...,a_rhs...
    #             # Array{δ}([a_lhs...])...,
    #             # Array{δ}([a_rhs...])...
    #         ]),0)


    #         # if neg>0
    #         #     return Array{δ}([[δ(:not, f) for f in f_lhs]...,[δ(:not, f) for f in f_rhs]...])
    #         # else
    #         #     return Array{δ}([f_lhs...,f_rhs...])
    #         # end
    #         # if neg
    #         #     Array{δ}([
    #         #         flatten(δ(:not,δ(d.args[1].head,d.args[1].args...)),!neg)...,
    #         #         flatten(δ(:not,δ(d.args[2].head,d.args[2].args...)),!neg)...
    #         #         ]) 
    #         # else 
    #         #     Array{δ}([
    #         #         flatten(δ(d.args[1].head,d.args[1].args...),!neg)...,
    #         #         flatten(δ(d.args[2].head,d.args[2].args...),!neg)...
    #         #         ]) 
    #         # end
            
    #     elseif d.head==:not
    #         # return Array{δ}([[δ()]])
    #         # "Call flatten with modulo the number of current negations, to keep them trimmed."
    #         # new_neg = (neg+1)%2
    #         flat = flatten(δ(d.args[1].head,d.args[1].args...);neg=neg+1)

    #         return flat

    #         # # is the root of a neg-tree?
    #         # if neg==0
    #         #     # return (Array{δ}([
    #         #     #     (flat[2]%2>0) ? [δ(:not,f) for f in flat[1]] : flat...
    #         #     # ]),0)

    #         #     if flat[2]%2>0
    #         #         return (Array{δ}([[δ(:not,f) for f in flat[1]]...]),0)
    #         #     else
    #         #         return (Array{δ}([flat...]),0)
    #         #     end
    #         # else
    #         #     # is just part of a larger neg tree, pass upwards
    #         #     return (Array{δ}([flat[1]...]),flat[2]+1)
    #         # end

    #         # if new_neg>0
    #         #     return Array{δ}([[δ(:not, f) for f in flat]...])
    #         # else
    #         #     return Array{δ}([flat...])
    #         # end
    #         # if neg
    #         #     return Array{δ}([[f for f in flatten(δ(d.args[1].head,d.args[1].args...);neg=neg+1)]...])
    #         # else
    #         #     return Array{δ}([[δ(:not, f) for f in flatten(δ(d.args[1].head,d.args[1].args...);neg=neg+1)]...])
    #         # end

    #         # if neg
    #         #     Array{δ}([
    #         #         flatten(δ(:not,δ(d.args[1].head,d.args[1].args...)),!neg)...
    #         #     ])
    #         # else 
    #         #     Array{δ}([
    #         #         flatten(δ(d.args[1].head,d.args[1].args...),!neg)...
    #         #     ])
    #         # end
    #     elseif d.head==:disjunct
    #         @warn "flatten(), head==:disjunct not supported."
    #     else
    #         return (Array{δ}([d]),neg)
    #         # if neg>0
    #         #     Array{δ}([δ(:not,d)])
    #         # else 
    #         #     Array{δ}([d])
    #         # end
    #     end
    # end

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