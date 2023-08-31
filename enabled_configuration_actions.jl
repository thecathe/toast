module EnabledConfigurationActions

    import Base.show
    import Base.string

    using ..General
    using ..SessionTypes
    using ..SessionTypeActions
    using ..ClockValuations
    using ..TransitionTimeSteps
    using ..Configurations
    using ..Evaluate

    
    export IsEnabled
    
    struct IsEnabled
        enabled::Bool
        actions::Array{Action}
        val::Valuations
        typ::S
        kind::Symbol
        IsEnabled(c::Social) = IsEnabled(Local(c.valuations,c.type))
        function IsEnabled(c::Local,kind::Symbol=:comm) 
            val=c.valuations
            t=c.type

            @assert kind in [:send,:recv,:comm] "IsEnabled, kind ($(string(kind))) not expected, expects: $(string([:send,:recv]))"

            if t.kind in [:interaction,:choice]
                # consistent
                if t.kind==:interaction
                    _type = S(Choice([t.child]))
                elseif t.kind==:choice
                    _type = t
                else
                    @error "IsEnabled, kind ($(t.kind)) not expected"
                end


                # collect all relevant actions that are satisfied now
                _actions = Array{Action}([])
                for i in _type.child.children
                    if (kind==:comm || kind==i.direction) && Eval(val,i.δ).result
                        push!(_actions,Action(i))
                    end
                end

                _enabled = !isempty(_actions)

                new(_enabled,_actions,val,_type,kind)

            else
                @error "IsEnabled, kind ($(t.kind)) not expected"
            end
        end
    end
    Base.show(e::IsEnabled, io::Core.IO = stdout) = print(io,string(e))
    Base.string(e::IsEnabled) = string(isempty(e.actions) ? "(no viable actions)" : join([string(a) for a in e.actions],"\n"))

end