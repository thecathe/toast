module BoundsOfConstraints

    import Base.string

    using ..LogicalClocks

    export δBounds

    """
    bounds are exclusive, so ≥ ≤ bounds are added twice (as part of eq_bounds)
    """
    struct δBounds
        clocks::Array{String}
        bounds::Dict{String,Array{Tuple{Num,Union{Num,Bool}}}}

        normalised::Bool

        function δBounds(d::δ;normalise::Bool = true)
            if normalise
                c = normaliseδ(d)
            else 
                c = d
                @warn "δBounds, not normalised."
            end

            raw_bounds = Dict{String,Array{DBC}}([(x, boundsOf(x,c)) for x in d.clocks])
            
            # skip if empty
            clocks = Array{String}([string(x) for x in keys(raw_bounds) if !isempty(raw_bounds[x])])
            
            @info "δBounds, raw: $(string(join([string(join([string(r) for r in raw_bounds[x]])) for x in clocks], ", ")))."


            # pair up bounds
            bounds =  Dict{String,Array{Tuple{Num,Union{Num,Bool}}}}([(x, []) for x in clocks])

            # for each clock
            for x in clocks
                lower_bounds = Array{DBC}([])
                upper_bounds = Array{DBC}([])
                eq_bounds = Array{DBC}([])
                # for each DBC 
                for y in raw_bounds[x]
                    if y.zone==:gtr
                        push!(lower_bounds,y)
                    elseif y.zone==:geq
                        push!(lower_bounds,y)
                        push!(eq_bounds,y)
                    elseif y.zone==:les
                        push!(upper_bounds,y)
                    elseif y.zone==:leq
                        push!(upper_bounds,y)
                        push!(eq_bounds,y)
                    elseif y.zone==:eq
                        push!(eq_bounds,y)
                    else
                        @warn("δBounds (of $(string(x))), unexpected zone in raw_bounds: $(string(y.zone)).")
                    end
                end

                unique!(lower_bounds)
                unique!(upper_bounds)
                unique!(eq_bounds)

                @info "δBounds (of $(string(x))), lb: $(string(join([string(l) for l in lower_bounds], ", ")))."
                @info "δBounds (of $(string(x))), ub: $(string(join([string(u) for u in upper_bounds], ", ")))."
                @info "δBounds (of $(string(x))), eq: $(string(join([string(e) for e in eq_bounds], ", ")))."

                # add :eq to bounds
                foreach(z -> push!(bounds[x], (z.constant,z.constant)), eq_bounds)

                # pair up bounds
                sort!(lower_bounds; by=a->a.constant)
                sort!(upper_bounds; by=a->a.constant)

                # match each lb to their nearest ub
                for l in lower_bounds
                    # no possible ub, just add greatest ub
                    if length(upper_bounds)==0
                        @info "δBounds (of $(string(x))), lb, no possible ub: $(string(l))"
                        push!(bounds[x], (l.constant,true))
                        continue
                    end

                    # fresh ub (index)
                    ub = nothing
                    ub_index = nothing
                    # search ub
                    for i in range(1,length(upper_bounds))
                        u = upper_bounds[i]
                        if (ub===nothing || ub < u) && l.constant <= u.constant
                            ub = u
                            ub_index = i
                            @info "δBounds (of $(string(x))), lb, searching ub ($(string(i))/$(string(length(upper_bounds)))), assigned: $(string(ub))"
                        end
                    end

                    # no ub found
                    if ub===nothing
                        push!(bounds[x], (l.constant,true))
                        @info "δBounds (of $(string(x))), no ub found: $(string(l))."
                        continue
                    end

                    @info "δBounds (of $(string(x))), pair found: $(string(l)) and $(string(ub))."
                    push!(bounds[x], (l.constant,ub.constant))
                    deleteat!(upper_bounds, ub_index)

                end

                # pair any remaining ub with 0
                for u in upper_bounds
                    push!(bounds[x], (0,u.constant))
                    @info "δBounds (of $(string(x))), remaining ub: $(string(u))."
                end
            end
            

            new(clocks, bounds, normalise)
        end

        function boundsOf(x::String,d::δ)::Array{DBC}
            head=d.head

            if head==:tt
                return []
            
            elseif head==:not
                # inner = d.args[1]
                # unsure if this should effect anything? not sure
                @warn "boundsOf($x) $(head), found: $(string(d))."
                return []

            elseif head==:eq && d.args[1]==x
                return [DBC(:eq,d.args[2])]

            elseif head==:and && x ∈ d.clocks
                # :and => take only the greatest upper and smallest lower
                # ! must only return an upper and lower, as otherwise always infeasible 
                # OR, the are overlapping
                lhs = boundsOf(x,d.args[1])
                rhs = boundsOf(x,d.args[2])

                # if either is empty, return non-empty one
                if isempty(lhs) || isempty(rhs)
                    return [lhs...,rhs...]
                end

                # if x ∉ d.clocks
                #     @info "boundsOf($x) $(string(head)), $x not in $(string(d.clocks))."
                # end

                # @info "boundsOf($x) $(string(head)), lhs: $(string(join([string(l) for l in lhs], ", ")))."
                # @info "boundsOf($x) $(string(head)), rhs: $(string(join([string(r) for r in rhs], ", ")))."

                lower_bound = nothing
                upper_bound = nothing

                lower_bounded = false
                upper_bounded = false
                # for all
                for b in Array{DBC}([lhs...,rhs...])
                    if b.zone ∈ [:gtr,:geq]
                        if upper_bound===nothing || (upper_bound isa DBC && upper_bound.constant < b.constant)
                            upper_bound = b
                            upper_bounded = true
                        end

                    elseif b.zone ∈ [:les,:leq]
                        if lower_bound===nothing || (lower_bound isa DBC && lower_bound.constant > b.constant)
                            lower_bound = b
                            lower_bounded = true
                        end

                    elseif b.zone==:eq
                        # try to replace both
                        if lower_bound===nothing || (lower_bound isa DBC && lower_bound.constant > b.constant)
                            lower_bound = b
                            lower_bounded = true
                        end
                        if upper_bound===nothing || (upper_bound isa DBC && upper_bound.constant < b.constant)
                            upper_bound = b
                            upper_bounded = true
                        end

                    else
                        @warn "boundsOf($x) $(string(head)), unhandled: $(string(b))."
                    end
                end

                result = Array{DBC}([])

                if lower_bounded
                    @assert lower_bound!==nothing "boundsOf($x) $(string(head)), lower_bound is nothing: $(string(d))."
                    push!(result, lower_bound)
                end
                if upper_bounded
                    @assert upper_bound!==nothing "boundsOf($x) $(string(head)), upper_bound is nothing: $(string(d))."
                    push!(result, upper_bound)
                end

                return result

            elseif head==:or && x ∈ d.clocks
                # :or => add the bounds of each branch
                return [boundsOf(x,d.args[1])...,boundsOf(x,d.args[2])...]

            elseif head ∈ [:eq,:leq,:les,:geq,:gtr] && d.args[1]==x
                return [DBC(head,d.args[2])]

            else
                # @warn "boundsOf($x), unexpected head: $(string(head))."
                return []
            end

        end


    end

    function Base.string(b::δBounds)
        return string(join([
            string("[$(x): $(string(join([string("($(y[1]), $(y[2]))") for y in b.bounds[x]], ", ")))]")
            for x in keys(b.bounds)
        ], ", "))
    end
    
    #
    # bounds of δ
    #
    # export boundsOf
    # function boundsof(x::String,f::δ)::Array{Tuple{Num,Union{Bool,Num}}}
    #     @assert f.head==:flat "bounds requires flattened δ."
    #     return boundsOf(x,Array{δ}([f.args[1]...]))
    # end
    # function boundsOf(x::String,f::Array{δ})::Array{Tuple{Num,Union{Bool,Num}}}#::Tuple{Array{Num},Array{Union{Bool,Num}}}#::Tuple{Num,Union{Bool,Num}}
    function boundsOfOLD(x::String,f::δ)::Array{Tuple{Num,Union{Bool,Num}}}#::Tuple{Array{Num},Array{Union{Bool,Num}}}#::Tuple{Num,Union{Bool,Num}}
    #? function boundsOf(c::δ,p::Array{String})::Tuple{δ,Array{Tuple{String,Tuple{Num,Union{Bool,Num}}}}}
        # lower_bound = 0
        # upper_bound = true
        lower_bounds = Array{Num}([])
        upper_bounds = Array{Num}([])
        # array of tuples indicating eq (bool indicates neg)
        # TODO change this to instead add to the lb and ub (if neg, )
        # ? maybe this kind of thing needs to be overhauled, to be able to show if it is inclusive or exclusive ?
        eq_constraints = Array{Tuple{Bool,Num}}([])



        # always_enabled = false
        # go through each δ and find ones that pertain to x
        for d in f
            @debug "bounds, for: $(string(d))."
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


                elseif child.head ∈ [:deq,:dgtr]
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


            elseif d.head ∈ [:deq,:dgtr]
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

        @debug "bounds, lower:\n$(string(join([string(l) for l in lower_bounds], ", ")))."
        @debug "bounds, upper:\n$(string(join([string(u) for u in upper_bounds], ", ")))."

        # match each lowerbound to their nearest upper bound
        for lb in lower_bounds
            upper_bound = nothing
            upper_bound_index = nothing
            if length(upper_bounds) > 0
                # for ub in upper_bounds
                for ub_index in range(1, length(upper_bounds))
                    ub = upper_bounds[ub_index]
                    if (upper_bound === nothing || ub < upper_bound) && lb <= ub
                        upper_bound = ub
                        upper_bound_index = ub_index
                    end
                end

                if upper_bound === nothing
                    # no upperbound given
                    push!(paired_bounds, (lb,true))
                else
                    # @info "bounds, upper_bound = \"$(upper_bound_index)\""
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

        @debug "bounds, pairs: $(string(join([string("($(p[1]), $(p[2]))") for p in paired_bounds],"; ")))."

        return paired_bounds

    end


end