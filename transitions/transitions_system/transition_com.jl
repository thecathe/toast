module SystemTransitionCom

    import Base.show
    import Base.string
    import Base.rand
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SystemTransition
    import ..Transitions.SocialTransition
    import ..Transitions.Send!
    import ..Transitions.Que!
    # using ..SocialTransitionSend
    # using ..SocialTransitionQue

    export Com!, ComL!, ComR!

    struct ComL! <: SystemTransition
        success::Bool
        lhs_success::Bool
        rhs_success::Bool

        unfolded::Bool
        unfolded_str::String

        function ComL!(c::System,m::Msg)

            lhs_copy = deepcopy(c.lhs)
            rhs_copy = deepcopy(c.rhs)

            # elevate lhs to Send, rhs to Que
            lhs_send = Send!(lhs_copy,Action(:send,m))
            rhs_que = Que!(rhs_copy,Action(:recv,m))

            lhs_success = lhs_send.success
            rhs_success = rhs_que.success
            success = lhs_success && rhs_success

            # @debug "[ComL] ($(string(m))) lhs_success==$(lhs_success)."
            # @debug "[ComL] ($(string(m))) rhs_success==$(rhs_success)."

            unfolded = lhs_send.unfolded
            unfolded_str = lhs_send.unfolded_str

            if success
                c.lhs = lhs_copy
                c.rhs = rhs_copy
            end
            
            new(success,lhs_success,rhs_success,unfolded,unfolded_str)

        end

    end

    struct ComR! <: SystemTransition
        success::Bool
        lhs_success::Bool
        rhs_success::Bool

        unfolded::Bool
        unfolded_str::String

        function ComR!(c::System,m::Msg)

            lhs_copy = deepcopy(c.lhs)
            rhs_copy = deepcopy(c.rhs)

            # elevate lhs to Que, rhs to Send
            lhs_que = Que!(lhs_copy,Action(:recv,m))
            rhs_Send = Send!(rhs_copy,Action(:send,m))

            lhs_success = lhs_que.success
            rhs_success = rhs_Send.success
            success = lhs_success && rhs_success

            @debug "[ComR] ($(string(m))) lhs_success==$(lhs_success)."
            @debug "[ComR] ($(string(m))) rhs_success==$(rhs_success)."

            unfolded = rhs_Send.unfolded
            unfolded_str = rhs_Send.unfolded_str

            if success
                c.lhs = lhs_copy
                c.rhs = rhs_copy
            end
            
            new(success,lhs_success,rhs_success,unfolded,unfolded_str)

        end

    end

    #
    #
    #
    """
    Com! succeeds if either of ComL! or ComR! succeeds, and then returns the result of a random successful one.
    """
    struct Com! <: SystemTransition
        success::Bool
        lhs_success::Bool
        rhs_success::Bool

        l_success::Bool
        r_success::Bool
        lhs_taken::Bool
        rhs_taken::Bool

        lhs_unfolded::Bool
        lhs_unfolded_str::String

        rhs_unfolded::Bool
        rhs_unfolded_str::String

        function Com!(c::System,m::Msg)

            lhs_copy = deepcopy(c)
            rhs_copy = deepcopy(c)

            l_com = ComL!(lhs_copy,m)
            r_com = ComR!(rhs_copy,m)

            l_success = l_com.success
            r_success = r_com.success
            success = l_success || r_success

            @debug "[Com!] l_success==$(l_success)."
            @debug "[Com!] r_success==$(r_success)."

            if l_success && r_success
                if rand(1:2)==1
                    c.lhs = lhs_copy.lhs
                    c.rhs = lhs_copy.rhs
                    lhs_taken = true
                    rhs_taken = false
                    lhs_unfolded = l_com.unfolded
                    lhs_unfolded_str = l_com.unfolded_str
                    rhs_unfolded = false
                    rhs_unfolded_str = ""
                    lhs_success = l_com.lhs_success
                    rhs_success = l_com.rhs_success
                else
                    c.lhs = rhs_copy.lhs
                    c.rhs = rhs_copy.rhs
                    lhs_taken = false
                    rhs_taken = true
                    lhs_unfolded = false
                    lhs_unfolded_str = ""
                    rhs_unfolded = r_com.unfolded
                    rhs_unfolded_str = r_com.unfolded_str
                    lhs_success = r_com.lhs_success
                    rhs_success = r_com.rhs_success
                end
            elseif l_success
                c.lhs = lhs_copy.lhs
                c.rhs = lhs_copy.rhs
                lhs_taken = true
                rhs_taken = false
                lhs_unfolded = l_com.unfolded
                lhs_unfolded_str = l_com.unfolded_str
                rhs_unfolded = false
                rhs_unfolded_str = ""
                lhs_success = l_com.lhs_success
                rhs_success = l_com.rhs_success
            elseif r_success
                c.lhs = rhs_copy.lhs
                c.rhs = rhs_copy.rhs
                lhs_taken = false
                rhs_taken = true
                lhs_unfolded = false
                lhs_unfolded_str = ""
                rhs_unfolded = r_com.unfolded
                rhs_unfolded_str = r_com.unfolded_str
                lhs_success = r_com.lhs_success
                rhs_success = r_com.rhs_success
            else
                lhs_taken = false
                rhs_taken = false
                lhs_unfolded = false
                lhs_unfolded_str = ""
                rhs_unfolded = false
                rhs_unfolded_str = ""
                lhs_success = false
                rhs_success = false
            end

            new(success,lhs_success,rhs_success,l_success,r_success,lhs_taken,rhs_taken,lhs_unfolded,lhs_unfolded_str,rhs_unfolded,rhs_unfolded_str)
        end
    end

end