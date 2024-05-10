module ConstraintsIntersection

    import Base.show
    import Base.string

    import Base.intersect

    using ...LogicalClocks

    export δIntersection
    struct δIntersection
        value::Bool
        intersection::Union{Dict{String,Array{Tuple{δ,δ}}},Nothing}

        function δIntersection(_i_delta::δ,_j_delta::δ)
            i_delta = normaliseδ(_i_delta)
            j_delta = normaliseδ(_j_delta)
            # get bounds of each
            i_bounds = δBounds(_i_delta;normalise=true)
            j_bounds = δBounds(_j_delta;normalise=true)
            @info "i_bounds: $(string(i_bounds))"
            @info "j_bounds: $(string(j_bounds))"
            # check if either always interesects with anything
            if i_bounds.universal || j_bounds.universal
                return new(true,nothing)
            end
            # only want clocks that are in both
            all_clocks = unique([i_bounds.clocks...,j_bounds.clocks...])
            relavent_clocks = [c for c in all_clocks if c∈i_bounds.clocks && c∈j_bounds.clocks ]
            # go through each, check if any of the bounds overlap
            intersect = false # default
            overlapping_constraints = Dict{String,Array{Tuple{δ,δ}}}([])
            for c in relavent_clocks
                constraints_overlap = false
                i_c = i_bounds.bounds[c]
                j_c = j_bounds.bounds[c]
                # for each bound on clock c in i
                for i_b in i_c
                    # for each bound on clock c in j
                    for j_b in j_c
                        # TODO :: check if diagonal constraints overlap
                        i_lb = i_b[1]
                        i_ub = i_b[2]
                        j_lb = j_b[1]
                        j_ub = j_b[2]

                        @debug "i_lb: $(string(i_lb))"
                        @debug "i_ub: $(string(i_ub))"
                        @debug "j_lb: $(string(j_lb))"
                        @debug "j_ub: $(string(j_ub))"

                        # i:(3, 5) j:(4,_)
                        if i_lb < j_lb && i_ub > j_lb
                            constraints_overlap = true
                            break
                        
                        # i:(3, 5) j:(_,4)
                        elseif i_lb < j_ub && i_ub > j_ub
                            constraints_overlap = true
                            break

                        # i:(4,_) j:(3, 5)
                        elseif j_lb < i_lb && j_ub > i_lb
                            constraints_overlap = true
                            break
                        
                        # i:(_,4) j:(3, 5)
                        elseif j_lb < j_ub && j_ub > i_ub
                            constraints_overlap = true
                            break
                        
                        # else
                        #     @info "do not overlap: $(string(i_b)) ∩ $(string(j_b)))"
                        end
                    end
                end
                if constraints_overlap
                    @info "overlap on $(string(c))"
                    overlapping_constraints[c]=[get(overlapping_constraints,c,[])...,(i_delta,j_delta)]
                    intersect = true
                else 
                    @info "no overlap on $(string(c))"
                end
            end

            new(intersect,overlapping_constraints)
        end

    end

    Base.intersect(i_delta::δ,j_delta::δ) = δIntersection(i_delta,j_delta).value
    
    Base.show(d::δIntersection, io::Core.IO = stdout) = print(io, string(d))
    Base.show(d::δIntersection, mode::Symbol, io::Core.IO = stdout) = print(io, string(d, mode))

    function Base.string(d::δIntersection, mode::Symbol = :default) 

        if d.intersection isa Nothing
            return "intersect = $(d.value) (universal)"
        else

            arr = Array{String}([string("$(string(c[1])) ∩ $(string(c[2]))") for k in keys(d.intersection) for c in d.intersection[k]])

            str = "intersect = $(string(d.value))$(d.intersection isa Nothing ? " (universal)" : "\n$(join(arr,"\n"))")"
            return str

        end

    end
end
