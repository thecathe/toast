module Configurations

    abstract type Configuration end
    export Configuration

    include("configurations/config_local.jl")
    using .LocalConfigurations
    export Local

    include("configurations/config_queue.jl")
    using .ConfigurationQueues
    export Queue, head!

    include("configurations/config_social.jl")
    using .SocialConfigurations
    export Social

    include("configurations/config_system.jl")
    using .SystemConfigurations
    export System
    
    include("configurations/config_evaluate.jl")
    using .ConfigurationEvaluations
    export Evaluate!

    include("configurations/config_transition.jl")
    using .ConfigurationTransitions
    # export 


end