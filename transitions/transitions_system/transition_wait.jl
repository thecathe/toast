module SystemTransitionWait

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SystemTransition
    # import ..Transitions.Transition!
    using ..SocialTransitionTime

    export Wait!

    "Check that each can success when elevated to [time]"
    struct Wait! <: SystemTransition
        success::Bool

        lhs::Bool
        rhs::Bool
        
        lhs_unfolded::Bool
        lhs_unfolded_str::String

        rhs_unfolded::Bool
        rhs_unfolded_str::String

        function Wait!(c::System,t::Num)

            lhs_copy = deepcopy(c.lhs)
            rhs_copy = deepcopy(c.rhs)

            lhs_time = Time!(lhs_copy,t)
            rhs_time = Time!(rhs_copy,t)

            lhs_success = lhs_time.success
            rhs_success = rhs_time.success
            success = lhs_success && rhs_success

            lhs_unfolded=lhs_time.unfolded
            lhs_unfolded_str=lhs_time.unfolded_str

            rhs_unfolded=lhs_time.unfolded
            rhs_unfolded_str=lhs_time.unfolded_str

            if success
                c.lhs = lhs_copy
                c.rhs = rhs_copy
            end
            
            new(success, lhs_success, rhs_success, lhs_unfolded, lhs_unfolded_str, rhs_unfolded, rhs_unfolded_str)

        end

    end

end