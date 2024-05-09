module ConstraintNormalisation

    using ..LogicalClocks

    export normaliseδ

    """
    recursively traverses δ finding patterns and normalising them (converting them to their simplest form)
    """
    function normaliseδ(c::δ)::δ
        d = deepcopy(c)
        head = d.head

        # @info "normalise $(string(d))."

        if head==:tt
            return c

        elseif head==:not
            # check inner
            inner = d.args[1]
            inner_head = inner.head
            
            if inner_head==:tt
                return c

            elseif inner_head==:not
                # double negation cancels out
                return normaliseδ(inner.args[1])

            elseif inner_head==:and
                # convert to OR 
                lhs = inner.args[1]
                rhs = inner.args[2]
                return δ(:or, normaliseδ(δ(:not,lhs)),normaliseδ(δ(:not,rhs)))

            elseif inner_head==:or
                # convert to AND
                lhs = inner.args[1]
                rhs = inner.args[2]
                return δ(:and, normaliseδ(δ(:not,lhs)),normaliseδ(δ(:not,rhs)))

            elseif inner_head==:geq
                return δ(:les,inner.args[1],inner.args[2])

            elseif inner_head==:les
                return δ(:geq,inner.args[1],inner.args[2])

            elseif inner_head==:leq
                return δ(:gtr,inner.args[1],inner.args[2])

            elseif inner_head==:gtr
                # @info "normaliseδ:not:gtr"
                return δ(:leq,inner.args[1],inner.args[2])

            elseif inner_head==:eq
                return δ(:or,δ(:les,inner.args[1],inner.args[2]),δ(:gtr,inner.args[1],inner.args[2]))

            else
                @warn "normaliseδ:not, unexpected inner_head: $(inner_head)."
                return normaliseδ(inner)
            end

        elseif head==:or
            lhs = d.args[1]
            rhs = d.args[2]

            # only if about the same constraint
            if lhs.clocks == rhs.clocks && lhs.head==:eq && rhs.head==:not
                rhs_inner = rhs.args[1]

                if rhs_inner.head==:geq
                    return δ(:leq,rhs.args[1],rhs.args[2])
                elseif rhs.head==:leq
                    return δ(:geq,rhs.args[1],rhs.args[2])
                else
                    return c
                end
            else
                return δ(:or,normaliseδ(lhs),normaliseδ(rhs))
            end


        elseif head==:and
            init_lhs = d.args[1]
            init_rhs = d.args[2]

            # continue going if either are and/or
            if init_lhs.head∈[:and,:or]
                norm_lhs = normaliseδ(init_lhs)
            else
                norm_lhs = init_lhs
            end
            if init_rhs.head∈[:and,:or]
                norm_rhs = normaliseδ(init_rhs)
            else
                norm_rhs = init_rhs
            end

            # only if about the same clocks
            if norm_lhs.clocks == norm_rhs.clocks
                # @info "normaliseδ:and same clocks"

                #
                # combine constraints (i.e.: (not:leq)==(gtr))
                #

                # lhs not:geq => les
                if norm_lhs.head==:not 
                    lhs_inner = norm_lhs.args[1]
                    if lhs_inner.head==:geq
                        lhs = δ(:les,lhs_inner.args[1],lhs_inner.args[2])
                    else
                        lhs = norm_lhs
                    end
                # lhs not:gtr => leq
                elseif norm_lhs.head==:not 
                    lhs_inner = norm_lhs.args[1]
                    if lhs_inner.head==:gtr
                        lhs = δ(:leq,lhs_inner.args[1],lhs_inner.args[2])
                    else
                        lhs = norm_lhs
                    end
                # lhs not:leq => gtr
                elseif norm_lhs.head==:not 
                    lhs_inner = norm_lhs.args[1]
                    if lhs_inner.head==:leq
                        lhs = δ(:gtr,lhs_inner.args[1],lhs_inner.args[2])
                    else
                        lhs = norm_lhs
                    end
                # lhs not:les => geq
                elseif norm_lhs.head==:not 
                    lhs_inner = norm_lhs.args[1]
                    if lhs_inner.head==:les
                        lhs = δ(:geq,lhs_inner.args[1],lhs_inner.args[2])
                    else
                        lhs = norm_lhs
                    end
                else
                    lhs = norm_lhs
                end

                # rhs not:geq => les
                if norm_rhs.head==:not 
                    rhs_inner = norm_rhs.args[1]
                    if rhs_inner.head==:geq
                        rhs = δ(:les,rhs_inner.args[1],rhs_inner.args[2])
                    else
                        rhs = norm_rhs
                    end
                # rhs not:gtr => leq
                elseif norm_rhs.head==:not 
                    rhs_inner = norm_rhs.args[1]
                    if rhs_inner.head==:gtr
                        rhs = δ(:leq,rhs_inner.args[1],rhs_inner.args[2])
                    else
                        rhs = norm_rhs
                    end
                # rhs not:leq => gtr
                elseif norm_rhs.head==:not 
                    rhs_inner = norm_rhs.args[1]
                    if rhs_inner.head==:leq
                        rhs = δ(:gtr,rhs_inner.args[1],rhs_inner.args[2])
                    else
                        rhs = norm_rhs
                    end
                # rhs not:les => geq
                elseif norm_rhs.head==:not 
                    rhs_inner = norm_rhs.args[1]
                    if rhs_inner.head==:les
                        rhs = δ(:geq,rhs_inner.args[1],rhs_inner.args[2])
                    else
                        rhs = norm_rhs
                    end
                else
                    rhs = norm_rhs
                end

                #
                # combine constraints (i.e.: (not:eq and leq)==(les))
                #

                # simplify to leq
                if lhs.head==:geq && rhs.head==:not
                    rhs_inner = rhs.args[1]

                    if rhs_inner.head==:eq
                        return δ(:gtr,rhs.args[1],rhs.args[2])
                    else
                        # dont change
                        return c
                    end
                
                # simplify to leq
                elseif rhs.head==:geq && lhs.head==:not
                    lhs_inner = lhs.args[1]

                    if lhs_inner.head==:eq
                        return δ(:gtr,lhs.args[1],lhs.args[2])
                    else
                        # dont change
                        return c
                    end

                # simplify to geq
                elseif lhs.head==:leq && rhs.head==:not
                    rhs_inner = rhs.args[1]

                    if rhs_inner.head==:eq
                        return δ(:les,rhs.args[1],rhs.args[2])
                    else
                        return c
                    end

                # simplify to geq
                elseif rhs.head==:leq && lhs.head==:not
                    lhs_inner = lhs.args[1]
                    
                    if lhs_inner.head==:eq
                        return δ(:les,lhs.args[1],lhs.args[2])
                    else
                        return c
                    end

                else
                    # 
                    return δ(:and,normaliseδ(lhs),normaliseδ(rhs))
                end
            else
                return δ(:and,normaliseδ(norm_lhs),normaliseδ(norm_rhs))
            end

        else
            return c

        end
    end


end