module LocalTransitionUnfold

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    export Unfold!

    struct Unfold!
        success::Bool
        identifier::String
        unfold_num::UInt8
        # unfolding::S
        # initate unfold
        function Unfold!(c::Local) 
            config = c
            # config = deepcopy(c)
            Unfold!(config,config.type)
        end
        #
        function Unfold!(c::Local,type::μ)
            id = type.identity
            child = type.child
            iteration = type.iteration + 1

            tail = μ(id,deepcopy(child),iteration)

            "Recursively traverse children and unfold any matching tails."
            unfolding = unfold_tail!(type.child,id,tail)
            unfold_num = unfolding[2]

            if unfolding[1]
                @warn "Unfold! μ is immedaitely followed by corresponding α, this is likley unintended:\n$(string(type,:expanded))"
            end

            "Progress to next type."
            c.type = type.child

            return new(true,id,unfold_num)
        end

        @doc raw"""
            unfold_tail!(type::T,target_id::String,tail::μ)::Tuple{::Bool,::UInt} where {T<:SessionType}

            returns a Tuple (unfold_child::Bool, sum_unfolds::UInt)
            
            - unfold_child::Bool indicates that the child is an α and should be unfolded (replaced with the tail).
            - sum_unfolds::UInt is the total number of such unfolds (above) that occured during the child unfolding.
        """
        function unfold_tail!(type::T,target_id::String,tail::μ)::Tuple{Bool,UInt8} where {T<:SessionType}
            "Check if found call that matches."
            if type isa α 
                if type.identity == target_id
                    return (true,1)
                end
                "Reached some other call."
                return (false,0)

            elseif type isa Choice
                sum_unfolds = 0
                "Explore all Interact in Choice and unfold."
                for interact in type
                    unfolding = unfold_tail!(interact,target_id,tail)
                    "If interact tail requires unfolding, unfold."
                    if unfolding[1]
                        interact.child = tail
                    end
                    "Add total number of unfolds from within interact child."
                    sum_unfolds += unfolding[2]
                end
                return (false,sum_unfolds)

            elseif type isa Interact
                "If Interact, return unfold_tail! on child, with Bool signifying it is not immediate."
                return (false,unfold_tail!(type.child,target_id,tail)[2])
            
            elseif type isa μ
                return (false,unfold_tail!(type.child,target_id,tail)[2])
            
            elseif type isa End
                return (false,0)

            else
                @error "Unfold! unfold_tail!, unexpected type ($(typeof(type)))."
            end
        end

    end
    
    Base.show(unfold::Unfold!, io::Core.IO = stdout) = print(io, string(unfold))
    
    Base.string(unfold::Unfold!) = string("μα[$(unfold.id)] #$(unfold.num_calls)")

end