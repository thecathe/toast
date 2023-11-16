module SystemTransitionPar

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SystemTransition
    # import ..Transitions.Transition!
    using ..SocialTransitionRecv

    export Par!, ParL!, ParR!

    struct ParL! <: SystemTransition
        success::Bool

        unfolded::Bool
        unfolded_str::String

        function ParL!(c::System)

            c_copy = deepcopy(c.lhs)
            recv = Recv!(c_copy)
            success = recv.success
            unfolded = recv.unfolded
            unfolded_str = recv.unfolded_str

            if success
                c.lhs = c_copy
            end

            new(success,unfolded,unfolded_str)

        end

    end

    struct ParR! <: SystemTransition
        success::Bool

        unfolded::Bool
        unfolded_str::String

        function ParR!(c::System)

            c_copy = deepcopy(c.rhs)
            recv = Recv!(c_copy)
            success = recv.success
            unfolded = recv.unfolded
            unfolded_str = recv.unfolded_str

            if success
                c.rhs = c_copy
            end

            new(success,unfolded,unfolded_str)

        end


    end

    #
    #
    #
    struct Par! <: SystemTransition
        success::Bool
        
        lhs_taken::Bool
        rhs_taken::Bool

        unfolded::Bool
        unfolded_str::String

        function Par!(c::System)

            lhs_copy = deepcopy(c)
            rhs_copy = deepcopy(c)

            l_par = ParL!(lhs_copy)
            r_par = ParR!(rhs_copy)

            l_success = l_par.success
            r_success = r_par.success
            success = l_success || r_success


            if l_success && r_success
                if rand(1:2)==1
                    c.lhs = lhs_copy.lhs
                    c.rhs = lhs_copy.rhs
                    lhs_taken = true
                    rhs_taken = false
                    unfolded = l_par.unfolded
                    unfolded_str = l_par.unfolded_str
                else
                    c.lhs = rhs_copy.lhs
                    c.rhs = rhs_copy.rhs
                    lhs_taken = false
                    rhs_taken = true
                    unfolded = r_par.unfolded
                    unfolded_str = r_par.unfolded_str
                end
            elseif l_success
                c.lhs = lhs_copy.lhs
                c.rhs = lhs_copy.rhs
                lhs_taken = true
                rhs_taken = false
                unfolded = l_par.unfolded
                unfolded_str = l_par.unfolded_str
            elseif r_success
                c.lhs = rhs_copy.lhs
                c.rhs = rhs_copy.rhs
                lhs_taken = false
                rhs_taken = true
                unfolded = r_par.unfolded
                unfolded_str = r_par.unfolded_str
            else
                lhs_taken = false
                rhs_taken = false
                unfolded = false
                unfolded_str = ""
            end

            new(success,lhs_taken,rhs_taken,unfolded,unfolded_str)

        end

    end

end