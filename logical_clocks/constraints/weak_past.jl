module WeakPast

    import Base.show
    import Base.string

    using ..LogicalClocks

    export δ⬇

    struct δ⬇
        origin::δ
        past::δ
        normalised::Bool

        function δ⬇(d::δ;normalise::Bool = true) 
            
            if normalise
                origin = normaliseδ(deepcopy(d))
            else
                origin = deepcopy(d)
                @warn "δ⬇, not normalised."
            end
            
            new(origin,pastOf(origin),normalise)
        end

        function pastOf(d::δ)::δ
            # return pastOf(c,c.clocks)
            # return pastOf(c,[(x,(0,true)) for x in c.clocks])
            head = d.head

            if head==:tt
                return d

            elseif head==:not
                return δ(:not,pastOf(d.args[1]))

            elseif head ∈ [:eq,:leq]
                return δ(:leq,d.args[1],d.args[2])

            elseif head ∈ [:gtr,:geq]
                return δ(:tt)

            elseif head ∈ [:or,:and]
                return δ(head,pastOf(d.args[1]),pastOf(d.args[2]))

            elseif head ∈ [:deq,:dgeq]
                return d

            else
                @warn "δ↓ pastOf(), unexpected head: $(string(head))."
                return d
            end

        end

        # function upperBound(c::δ)::Union{δ,Bool}#::Union{DBC,Bool}
        #     head=c.head
        #     if head==:tt
        #         return true

        #     elseif head ∈ [:eq,:leq]
        #         return δ(:leq,c.args[1],c.args[2])

        #     elseif head ∈ [:gtr,:geq]
        #         return true

        #     elseif head ∈ [:and,:or]
        #         lhs = upperBound(c.args[1])
        #         rhs = upperBound(c.args[2])

        #         if head==:and

        #         elseif head==:or
        #             # pick the highest one
        #             if lhs isa Bool
        #                 # use if not false
        #                 if lhs==true
        #                     return lhs
        #                 else
        #                     # just use rhs
        #                 end

        #                 if rhs isa Bool
        #                     return lhs || rhs
        #                 else
        #                     return lhs
        #                 end
        #             else
        #                 @assert lhs isa δ "δ↓ upperBound, lhs is not bool or δ: $(string(lhs))::$(typeof(lhs))."

        #                 if rhs isa Bool
        #                     return 

        #             end

        #         end

        #     elseif head==:not

        #     else

        #     end
        # end

        # function pastOf(c::δ,p::Array{String})::Tuple{δ,Array{Tuple{String,Tuple{Num,Union{Bool,Num}}}}}
        #     head = c.head

        #     if head==:tt
        #         return (c,p)

        #     elseif head==:or
        #         # add each of these
        #         lhs = pastOf(c.args[1],p)
        #         rhs = pastOf(c.args[2],p)
        #         # push!(p, [lhs[2]...])

        #     else
        #         @warn "δ↓ pastOf(), unexpected head: $(string(head))."
        #     end

        # end

    end




    Base.show(d::δ⬇, io::Core.IO = stdout) = print(io, string(d))
    Base.show(d::δ⬇, mode::Symbol, io::Core.IO = stdout) = print(io, string(d, mode))

    function Base.string(d::δ⬇, mode::Symbol = :default) 
        if mode==:default
            return "$(string(d.past)) = ↓($(string(d.origin)))"
        else
            @error "δ⬇.string, unexpected mode: $(string(mode))."
        end
    end
end