module ConstraintNormalisation

    using ..LogicalClocks

    export normaliseδ

    """
    recursively traverses δ finding patterns and normalising them (converting them to their simplest form)
    """
    function normaliseδ(z::δ)::δ
        d = deepcopy(z)
        head = d.head

        @debug "normalise $(string(d))."

        if head==:tt
            return d

        elseif head==:not
            # check inner
            inner = d.args[1]
            inner_head = inner.head
            
            if inner_head==:tt
                return d

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

        elseif head∈[:and,:or]
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

            if head==:or
                # only if about the same clocks
                if norm_lhs.clocks == norm_rhs.clocks
                    if norm_lhs.head==:not 
                        lhs_inner = norm_lhs.args[1]
                        # lhs not:geq => les
                        if lhs_inner.head==:geq
                            lhs = δ(:les,lhs_inner.args[1],lhs_inner.args[2])
                        # lhs not:gtr => leq
                        elseif lhs_inner.head==:gtr
                            lhs = δ(:leq,lhs_inner.args[1],lhs_inner.args[2])
                        # lhs not:leq => gtr
                        elseif lhs_inner.head==:leq
                            lhs = δ(:gtr,lhs_inner.args[1],lhs_inner.args[2])
                        # lhs not:les => geq
                        elseif lhs_inner.head==:les
                            lhs = δ(:geq,lhs_inner.args[1],lhs_inner.args[2])
                        else
                            lhs = norm_lhs
                        end
                    else
                        lhs = norm_lhs
                    end

                    if norm_rhs.head==:not 
                        rhs_inner = norm_rhs.args[1]
                        # rhs not:geq => les
                        if rhs_inner.head==:geq
                            rhs = δ(:les,rhs_inner.args[1],rhs_inner.args[2])
                        # rhs not:gtr => leq
                        elseif rhs_inner.head==:gtr
                            rhs = δ(:leq,rhs_inner.args[1],rhs_inner.args[2])
                        # rhs not:leq => gtr
                        elseif rhs_inner.head==:leq
                            rhs = δ(:gtr,rhs_inner.args[1],rhs_inner.args[2])
                        # rhs not:les => geq
                        elseif rhs_inner.head==:les
                            rhs = δ(:geq,rhs_inner.args[1],rhs_inner.args[2])
                        else
                            rhs = norm_rhs
                        end
                    else
                        rhs = norm_rhs
                    end
                    # @info "normaliseδ:or, $(string(c))"
                    # @info "normaliseδ:or, norm_lhs.head∈[:leq,:les]=$(string(lhs.head∈[:leq,:les]))"
                    # @info "normaliseδ:or, norm_rhs.head∈[:geq,:gtr]=$(string(rhs.head∈[:geq,:gtr]))"
                    # if lhs.head≠:not && rhs.head≠:not
                    #     @info "normaliseδ:or, norm_lhs.args[2] > norm_rhs.args[2]=$(string(lhs.args[2] > rhs.args[2]))"
                    # end
                    # @info "normaliseδ:or, norm_lhs.head∈[:leq,:les]=$(string(lhs.head∈[:geq,:gtr]))"
                    # @info "normaliseδ:or, norm_rhs.head∈[:geq,:gtr]=$(string(rhs.head∈[:leq,:les]))"
                    # if lhs.head≠:not && rhs.head≠:not
                    #     @info "normaliseδ:or, norm_rhs.args[2] > norm_lhs.args[2]=$(string(rhs.args[2] > lhs.args[2]))"
                    # end
                    # see if these equate to true (y>3 V y<5)==true
                    if lhs.head∈[:leq,:les] && rhs.head∈[:geq,:gtr] && lhs.args[2] > rhs.args[2]
                        @debug "normaliseδ:or, $(string(d)) is $(string(δ(:tt)))"
                        return δ(:tt)
                    elseif lhs.head∈[:geq,:gtr] && rhs.head∈[:leq,:les] && lhs.args[2] < rhs.args[2]
                        @debug "normaliseδ:or, $(string(d)) is $(string(δ(:tt)))"
                        return δ(:tt)
                    else
                        @debug "normaliseδ:or, $(string(d)) is not $(string(δ(:tt)))"
                        #
                        # combine constraints (i.e.: (not:les V :eq)==(geq)), (les V eq)==(leq)
                        #
                        
                        if lhs.head==:eq && rhs.head==:not
                            rhs_inner = rhs.args[1]

                            # simplify to geq
                            if rhs_inner.head==:les && lhs.args[1]==rhs_inner.args[1]
                                return δ(:geq,rhs.args[1],rhs.args[2])
                            # simplify to leq
                            elseif rhs_inner.head==:gtr && lhs.args[1]==rhs_inner.args[1]
                                return δ(:leq,rhs.args[1],rhs.args[2])
                            else
                                # dont change
                                return d
                            end

                        elseif rhs.head==:eq && lhs.head==:not
                            lhs_inner = lhs.args[1]

                            # simplify to geq
                            if lhs_inner.head==:les && lhs_inner.args[1]==rhs.args[1]
                                return δ(:geq,lhs.args[1],lhs.args[2])
                            # simplify to leq
                            elseif lhs_inner.head==:gtr && lhs_inner.args[1]==rhs.args[1]
                                return δ(:leq,lhs.args[1],lhs.args[2])
                            else
                                # dont change
                                return d
                            end

                        # simplify to geq
                        elseif lhs.head==:eq && rhs.head==:gtr && lhs.args[1]==rhs.args[1]
                            return δ(:leq,rhs.args[1],rhs.args[2])
                        elseif rhs.head==:eq && lhs.head==:gtr && lhs.args[1]==rhs.args[1]
                            return δ(:geq,lhs.args[1],lhs.args[2])

                        # simplify to leq
                        elseif lhs.head==:eq && rhs.head==:les && lhs.args[1]==rhs.args[1]
                            return δ(:leq,rhs.args[1],rhs.args[2])
                        elseif rhs.head==:eq && lhs.head==:les && lhs.args[1]==rhs.args[1]
                            return δ(:leq,lhs.args[1],lhs.args[2])

                        else
                            # 
                            return δ(:or,normaliseδ(lhs),normaliseδ(rhs))
                        end
                    end
                else
                    return δ(:or,norm_lhs,norm_rhs)
                end

            elseif head==:and
                @debug "normaliseδ:and."

                # only if about the same clocks
                if norm_lhs.clocks == norm_rhs.clocks
                    # @info "normaliseδ:and same clocks"

                    #
                    # combine constraints (i.e.: (not:leq)==(gtr))
                    #

                    if norm_lhs.head==:not 
                        lhs_inner = norm_lhs.args[1]
                        # lhs not:geq => les
                        if lhs_inner.head==:geq
                            lhs = δ(:les,lhs_inner.args[1],lhs_inner.args[2])
                        # lhs not:gtr => leq
                        elseif lhs_inner.head==:gtr
                            lhs = δ(:leq,lhs_inner.args[1],lhs_inner.args[2])
                        # lhs not:leq => gtr
                        elseif lhs_inner.head==:leq
                            lhs = δ(:gtr,lhs_inner.args[1],lhs_inner.args[2])
                        # lhs not:les => geq
                        elseif lhs_inner.head==:les
                            lhs = δ(:geq,lhs_inner.args[1],lhs_inner.args[2])
                        else
                            lhs = norm_lhs
                        end
                    else
                        lhs = norm_lhs
                    end

                    if norm_rhs.head==:not 
                        rhs_inner = norm_rhs.args[1]
                        # rhs not:geq => les
                        if rhs_inner.head==:geq
                            rhs = δ(:les,rhs_inner.args[1],rhs_inner.args[2])
                        # rhs not:gtr => leq
                        elseif rhs_inner.head==:gtr
                            rhs = δ(:leq,rhs_inner.args[1],rhs_inner.args[2])
                        # rhs not:leq => gtr
                        elseif rhs_inner.head==:leq
                            rhs = δ(:gtr,rhs_inner.args[1],rhs_inner.args[2])
                        # rhs not:les => geq
                        elseif rhs_inner.head==:les
                            rhs = δ(:geq,rhs_inner.args[1],rhs_inner.args[2])
                        else
                            rhs = norm_rhs
                        end
                    else
                        rhs = norm_rhs
                    end

                    @debug "normaliseδ:and lhs: $(string(lhs))"
                    @debug "normaliseδ:and rhs: $(string(rhs))"

                    #
                    # combine constraints (i.e.: (not:eq and leq)==(les))
                    #

                    # simplify to leq
                    if lhs.head==:geq && rhs.head==:not
                        rhs_inner = rhs.args[1]

                        if rhs_inner.head==:eq && lhs.args[1]==rhs_inner.args[1]
                            return δ(:gtr,rhs.args[1],rhs.args[2])
                        else
                            # dont change
                            return d
                        end
                    
                    # simplify to leq
                    elseif rhs.head==:geq && lhs.head==:not
                        lhs_inner = lhs.args[1]

                        if lhs_inner.head==:eq && lhs_inner.args[1]==rhs.args[1]
                            return δ(:gtr,lhs.args[1],lhs.args[2])
                        else
                            # dont change
                            return d
                        end

                    # simplify to geq
                    elseif lhs.head==:leq && rhs.head==:not
                        rhs_inner = rhs.args[1]

                        if rhs_inner.head==:eq && lhs.args[1]==rhs_inner.args[1]
                            return δ(:les,rhs.args[1],rhs.args[2])
                        else
                            return d
                        end

                    # simplify to geq
                    elseif rhs.head==:leq && lhs.head==:not
                        lhs_inner = lhs.args[1]
                        
                        if lhs_inner.head==:eq && lhs_inner.args[1]==rhs.args[1]
                            return δ(:les,lhs.args[1],lhs.args[2])
                        else
                            return d
                        end

                    else
                        # 
                        return δ(:and,normaliseδ(lhs),normaliseδ(rhs))
                    end
                else
                    @debug "normaliseδ:and different clocks"
                    return δ(:and,norm_lhs,norm_rhs)
                end
            end

        else
            return d

        end
    end


end