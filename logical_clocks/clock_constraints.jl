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
            else
                @error "δExpr.string, unexpected head: $(string(head)), $(string(args))"
            end
        else
            @error "δExpr.string, unexpected mode: $(mode), $(string(args))"
        end
    end

    export δ, supported_constraints
    const supported_constraints = [:tt, :not, :and, :eq, :geq, :deq, :dgeq, :flatten, :past, :disjunct]

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

                    # @warn args[1].head!=:flatten "δ($(head)) should not be used on already flattened δ: $(string(args[1]))"

                    _flat = Flatδ(args[1])
                    _clocks = Array{String}([])
                    foreach(d -> push!(_clocks, d.clocks...), _flat)
                    _expr = δConjunctify(_flat)
                    # println("\nδ(:flatten), expr: $(string(_expr))\n")
                    new(head, [_flat...], _expr, unique(_clocks))

                elseif head==:past
                    # :past - flatten and add addition constraints for each constrained clock :geq 0
                    @assert length(args)==1 "δ($(string(head))) expects 1 args: ($(length(args))) $(string(args))"
                    
                    if args[1].head==:flatten
                        _flat = args[1].args
                    else
                        @info "δ($(head)), flattening: $(string(args[1]))"
                        _flat = Flatδ(args[1])
                    end
                    _clocks = Array{String}([])
                    foreach(d -> push!(_clocks, d.clocks...), _flat)

                    _weak_past_children = Array{δ}([_flat...])
                    for x in _clocks
                        # add each constrained clock being >= 0
                        push!(_weak_past_children, δ(:geq, x, 0))
                    end
                    _expr = δConjunctify(_weak_past_children)
                    # println("\nδ(:past), expr: $(string(_expr))\n")
                    new(head, _weak_past_children, _expr, unique(_clocks))

                elseif head==:disjunct
                    # :disjunct => 
                    
                    # if args[1].head==:flatten
                    #     @assert length(args)==1 "δ($(head)), expects flattened child to be alone"
                    #     _flat = args[1].args
                    # else
                    #     @info "δ($(head)), flattening: $(string(args))"
                    #     _flat = Flatδ(args[1])
                    # end

                    # @info "δ($(head)), "
                    # @info "δ($(head)), args isa $(typeof(args)):\n$(join([string("\t$(string(d)) isa $(typeof(d))") for d in args],"\n"))\n"

                    # _flats = Array{δ}([[Array{δ}(Flatδ(d))...] for d in args])
                    _flats = Array{δ}([])
                    for d in args
                        push!(_flats, δ(:flatten, d))
                        # push!(_flats, Flatδ(d)...)
                    end
                    # _conjs = δConjunctify(_flats)
                    # _flat = Flatδ(_conjs)

                    _clocks = Array{String}([])
                    foreach(d -> push!(_clocks, d.clocks...), _flats)
                    # foreach(f -> foreach(d -> push!(_clocks, d.clocks...), f), _flats)
                    # for f in _flats
                    #     for d in f
                    #         push!(_clocks, d.clocks...)
                    #     end
                    # end

                    _expr = δDisjunctify(_flats)


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
            elseif head==:flatten
                string(join([string(c) for c in d.args], " ∧ "))
            elseif head==:past
                string("↓($(string(join([string(c) for c in d.args], " ∧ "))))")
            else
                @error "δ.string, unexpected head: $(string(d.head))"
            end
        else
            @error "δ.string, unexpected mode: $(string(mode))"
        end
    end

    
    #
    # flatten
    #
    struct Flatδ
        Flatδ(d::δ) = flatten(d)
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
        δConjunctify(f::T) where {T<:Array{δ}} = conjunctify(f)
    end

    # conjuctify flattned
    function conjunctify(f::T) where {T<:Array{δ}}
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
    struct δDisjunctify
        δDisjunctify(f::T) where {T<:Array{δ}} = disjunctify(f)
    end

    # disjunctify flattned
    function disjunctify(f::T) where {T<:Array{δ}}
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