module LocalTransitionUnfold

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    using ..TransitionsLocal

    export Unfold!

    struct Unfold! <: LocalTransition
        def::Def
        calls::UInt
        unfolding::S
        # initate unfold
        Unfold!(c::T) where {T<:Configuration} = Unfold!(c.type)
        function Unfold!(state::S)
            # unfold if def
            if state.child isa Def
                folded = Def(state.child.identity,deepcopy(state.child.child))
                call_id = folded.identity

                # seek and unfold in tail
                num_calls = unfold!(state.child.child,call_id,folded)

                # replace def with tail
                state.child=state.child.child

                new(folded,num_calls,state)
            else
                @error "Unfold!, state not unfoldable (type $(typeof(state.child))): $(string(state))"
            end
        end

        # continue unfold
        function unfold!(state::T,call_id::String,folded::Def) where {T<:SessionType}
            # check reached call immediately
            if state isa Call
                if state.identity==call_id
                    @error "unfold!, reached relevant call immediately after definition. *this is likely unintended*"
                    state.child = folded
                    return 1
                else
                    @error "unfold!, reached different call immediately after definition. *this is likely unintended*"
                    return 0
                end
            elseif state isa Choice
                num_calls = 0
                for c in state.children
                    # replace child with next fold, if call
                    if c.child isa Call
                        c.child = folded
                        num_calls += 1
                    else
                        num_calls += unfold!(c,call_id,folded)
                    end
                end
                return num_calls
            elseif state isa Interaction
                    # replace child with next fold, if call
                    if state.child isa Call
                        state.child = folded
                        return 1
                    else
                        return unfold!(state.child,call_id,folded)
                    end
            elseif state isa Def
                    # replace child with next fold, if call
                    if state.child isa Call
                        state.child = folded
                        return 1
                    else
                        return unfold!(state.child,call_id,folded)
                    end
            elseif state isa S
                    # replace child with next fold, if call
                    if state.child isa Call
                        state.child = folded
                        return 1
                    else
                        return unfold!(state.child,call_id,folded)
                    end
            elseif state isa End
                return 0
            else 
                @error "seeking unfold!, unexpected state (type $(typeof(state))): $(string(state))"
                return 0
            end
        end
    end
    Base.show(unfold::Unfold!, io::Core.IO = stdout) = print(io, string(unfold))
    function Base.string(unfold::Unfold!) 
        string("")
    end


end