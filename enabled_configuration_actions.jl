module EnabledConfigurationActions

    import Base.show
    import Base.string

    using ..General
    using ..Configurations
    using ..Evaluate
    using ..SessionTypes
    using ..ClockValuations

    
    export isEnabled
    
    struct IsEnabled
        enabled::Bool
        actions::Array{Action}
        val::Valuations
        typ::S
        kind::Symbol
        function IsEnabled(c::T,kind::Symbol=:comm) where {T<:Configuration}
            val=c.valuations
            t=c.type

            @assert kind in [:send,:recv] "IsEnabled, kind ($(string(kind))) not expected, expects: $(string([:send,:recv]))"

            if t.kind in [:interaction,:choice]
                # consistent
                if t.kind==:interaction
                    _type = S(Choice([t.child]))
                elseif t.kind==:choice
                    _type = t
                else
                    @error "IsEnabled, kind ($(t.kind)) not expected"
                end

                @assert kind in [:send,:recv] "IsEnabled, kind ($(string(kind))) not expected, expects: $(string([:send,:recv]))"

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
    function Base.string(e::IsEnabled) 
        return string(e.enabled ? string(e.kind==:comm ? "Any enabled actions:\n" : e.kind==:send ? "Enabled sending actions:\n" : "Enabled receiving actions:\n", isempty(e.actions) ? "error, no actions" : join(e.actions, "\n")) : "Error, no enabled actions.")
    end

    
    export EnabledActions

    struct EnabledActions
        send::LocalSteps
        recv::LocalSteps
        function EnabledActions(state::Local)
            send = LocalSteps(:send,state)
            recv = LocalSteps(:recv,state)
            new(send,recv)
        end
    end
    function Base.show(s::EnabledActions, io::Core.IO = stdout) 
        print(io, string("send: ", string(s.send), "\nrecv: ", string(s.recv)))
    end
    function Base.string(s::EnabledActions) 
        string(string(s.send),string(s.recv))
    end



end