module Configurations

    include("configurations/config_local.jl")
    using .LocalConfigurations
    export Local

    # include("configurations/config_social.jl")
    # using .SocialConfigurations
    # export Social

    # include("configurations/config_system.jl")
    # using .SystemConfigurations
    # export System

end