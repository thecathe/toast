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

    end

    struct ParR! <: SystemTransition

    end

    #
    #
    #
    struct Par! <: SystemTransition

    end

end