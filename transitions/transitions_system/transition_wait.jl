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

    struct Wait!

    end

end