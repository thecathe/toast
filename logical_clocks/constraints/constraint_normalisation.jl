module ConstraintNormalisation

    using ..LogicalClocks

    export normaliseδ

    """
    recursively traverses δ finding patterns and normalising them (converting them to their simplest form)
    """
    function normaliseδ(c::δ)::δ
        d = deepcopy(c)
        head = d.head

        # @debug "normalise $(string(d))."

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
                return δ(:leq,inner.args[1],inner.args[2])

            elseif inner_head==:eq
                return δ(:or,δ(:les,inner.args[1],inner.args[2]),δ(:gtr,inner.args[1],inner.args[2]))

            else
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
            lhs = d.args[1]
            rhs = d.args[2]

            # only if about the same constraint
            if lhs.clocks == rhs.clocks
                # simplify to leq
                if lhs.head==:geq && rhs.head==:not
                    rhs_inner = rhs.args[1]

                    if rhs_inner.head==:eq
                        return δ(:leq,rhs.args[1],rhs.args[2])
                    else
                        # dont change
                        return c
                    end
                
                # simplify to leq
                elseif rhs.head==:geq && lhs.head==:not
                    lhs_inner = lhs.args[1]

                    if lhs_inner.head==:eq
                        return δ(:leq,lhs.args[1],lhs.args[2])
                    else
                        # dont change
                        return c
                    end

                # simplify to geq
                elseif lhs.head==:leq && rhs.head==:not
                    rhs_inner = rhs.args[1]

                    if rhs_inner.head==:eq
                        return δ(:geq,rhs.args[1],rhs.args[2])
                    else
                        return c
                    end

                # simplify to geq
                elseif rhs.head==:leq && lhs.head==:not
                    lhs_inner = lhs.args[1]
                    
                    if lhs_inner.head==:eq
                        return δ(:geq,lhs.args[1],lhs.args[2])
                    else
                        return c
                    end

                else
                    # 
                    return δ(:and,normaliseδ(lhs),normaliseδ(rhs))
                end
            else
                return δ(:and,normaliseδ(lhs),normaliseδ(rhs))
            end

        else
            return c

        end
    end


end