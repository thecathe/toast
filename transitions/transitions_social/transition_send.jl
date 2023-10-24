module SocialTransitionSend

    import Base.show
    import Base.string
    
    using ..General
    using ..LogicalClocks
    using ..ClockValuations
    using ..SessionTypes
    using ..SessionTypeActions
    using ..Configurations

    using ..LocalTransitionAct

    export Send!

    struct Send!
        success::Bool
        label::Label
        resets::Labels
        Send!(c::Social,d::Symbol,m::Msg,p::Labels=Labels([])) = Send!(c,Action(d,m,p))
        function Send!(c::Social,a::Action)
            @assert a.direction==:send "Send!, action not send: $(string(a))"
            # elevate to act
            new(Act!(c,a)...)
        end
    end
    Base.show(l::Send!,io::Core.IO=stdout) = print(io,string(l))
    function Base.string(l::Send!) 
        if l.success
            string("⟶ $(string(l.label)) [$(string(l.resets)) ↦ 0]")
        else
            string("̸⟶ $(string(l.label)) [$(string(l.resets)) ↦ 0]")
        end
    end

end