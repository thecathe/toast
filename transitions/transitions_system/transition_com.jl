module SystemTransitionCom

    import Base.show
    import Base.string
    
    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations

    import ..Transitions.SystemTransition
    # import ..Transitions.Transition!
    using ..SocialTransitionSend
    using ..SocialTransitionQue

    export Com!, ComL!, ComR!

    struct ComL! <: SystemTransition

    end

    struct ComR! <: SystemTransition

    end

    #
    #
    #
    struct Com! <: SystemTransition

    end

end