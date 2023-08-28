module Transitions

    import Base.show
    import Base.string
    import Base.iterate
    import Base.length
    import Base.getindex
    import Base.isempty
    

    # import InteractiveUtils.subtypes

    using ..General
    using ..Configurations
    using ..Evaluate
    using ..SessionTypes
    using ..ClockValuations

    abstract type LabelledStep end

    export LocalStep, LocalSteps

    struct LocalStep <: LabelledStep
        kind::Symbol
        action::Action
        function LocalStep(kind::Symbol,action::Action) 
            @assert kind in [:send, :recv, :unfold, :call, :wait, :enque]
            new(kind,action)
        end
    end
    Base.show(s::LocalStep, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::LocalStep) = string(string(s.action))

    struct LocalSteps 
        kind::Symbol
        state::Local
        steps::Array{LocalStep}
        valid::Bool
        function LocalSteps(kind::Symbol,state::Local)
            @assert kind in [:send, :recv, :unfold, :call, :wait, :enqu]

            _local_steps = Array{LocalStep}([])
            if kind in [:send,:recv]
                # check for any enabled actions
                _res = IsEnabled(state,kind)
                if _res.enabled
                    # add each to local steps
                    for r in _res.actions
                        push!(_local_steps,LocalStep(kind,r))
                    end
                    new(kind,state,_local_steps,true)
                else
                    # no actions of specified kind
                    new(kind,state,[],false)
                end
            else
                @error "LocalSteps: doesnt handle kind ($(string(kind)))"
            end
        end
    end
    Base.show(s::LocalSteps, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::LocalSteps) = string( isempty(s) ? "∅" : string(join([string(x) for x in s.steps], "\n")))

    Base.length(s::LocalSteps) = length(s.steps)
    Base.isempty(s::LocalSteps) = isempty(s.steps)
    Base.getindex(s::LocalSteps, i::Int) = getindex(s.steps, i)

    Base.iterate(s::LocalSteps) = isempty(s) ? nothing : (getindex(s,1), Int(1))
    Base.iterate(s::LocalSteps, i::Int) = (i >= length(s)) ? nothing : (getindex(s,i+1), i+1)

    


    export SocialStep, SocialSteps

    struct SocialStep <: LabelledStep
        action::LocalSteps
        kind::Symbol
        function SocialStep(kind::Symbol,state::Social)
            @assert kind in [:send,:recv,:enqu,:wait,:nothing]

            new(LocalSteps(kind,state),kind)
        end
    end
    Base.show(s::SocialStep, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::SocialStep) = string(string(s.action))

    struct SocialSteps
        kind::Symbol
        state::Local
        steps::Array{SocialStep}
        valid::Bool
        function SocialSteps(kind::Symbol,state::Social)
            _social_steps = Array{SocialStep}([])
            _local_steps = LocalSteps(kind,state)
            if _local_steps.valid
                new(kind,state,_social_steps,true)
            else
                @error "SocialSteps, local not valid: $(string(_local_steps))"
            end            
        end
    end
    Base.show(s::SocialSteps, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::SocialSteps) = string(string(s.kind), ": ", string(join([string(x) for x in s.steps], "\n")))



    export SystemStep, SystemSteps

    struct SystemStep <: LabelledStep
        kind::Symbol
        lhs::SocialSteps
        rhs::SocialSteps
        function SystemStep(kind::Symbol,lhs::Social,rhs::Social)
            @assert kind in [:send,:dequ,:wait]
            
            if kind==:send
                new(kind,SocialSteps(:send,lhs),SocialSteps(:enqu,rhs))
            elseif kind==:dequ
                new(kind,SocialSteps(:recv,lhs),SocialSteps(:nothing,rhs))
            elseif kind==:wait
                max_lhs = 0
                max_rhs = 0
                # new(kind,SocialSteps())
            else
                @error "SystemStep, unknown kind: $(kind)"
            end
        end

        # function system_actions(lhs::Symbol,rhs::Symbol)
        #     if lhs==:send && rhs==:enque
        #         return (:tau, true)
        #     elseif lhs==:enque && rhs==:send
        #         return (:tau, true)
        #     elseif lhs==:recv && rhs==:nothing
        #         return (:tau, true)
        #     elseif lhs==:nothing && rhs==:recv
        #         return (:tau, true)
        #     elseif lhs==:wait && rhs==:wait
        #         return (:time, true)
        #     else
        #         @error "dual_actions($(string(lhs)), $(string(rhs))) unhandled"
        #     end
        #     return (~, false)
        # end
    end
    Base.show(s::SystemStep, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::SystemStep) = string(string(s.kind), ": ", string(s.lhs), " | ", string(s.rhs))


    struct SystemSteps
        state::System
        steps::Array{SystemStep}
        function SystemSteps(state::System)

            _lhs_send_futures = SystemStep(:send,state.lhs,state.rhs)
            _rhs_send_futures = SystemStep(:send,state.rhs,state.lhs)
            _sending_futures = Array{SystemStep}([_lhs_send_futures...,_rhs_send_futures...])
            
            _lhs_recv_futures = SystemStep(:dequ,state.lhs,state.rhs)
            _rhs_recv_futures = SystemStep(:dequ,state.rhs,state.lhs)
            _recving_futures = Array{SystemStep}([_lhs_recv_futures...,_rhs_recv_futures...])
            
            _lhs_wait_futures = SystemStep(:wait,state.lhs,state.rhs)
            _rhs_wait_futures = SystemStep(:wait,state.rhs,state.lhs)
            _waiting_futures = Array{SystemStep}([_lhs_wait_futures...,_rhs_wait_futures...])

            _possible_steps = Array{SystemStep}([_sending_futures...,_recving_futures...,_waiting_futures...])

            new(state,_possible_steps)
        end
    end
    Base.show(s::SystemSteps, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::SystemSteps) = string(string(s.state), ": ", string(join([string(x) for x in s.steps], "\n")))

    export StepDriver

    struct StepDriver
        state::System
        succ::SystemSteps
        function StepDriver(state::System)
            new(state,SystemSteps(state))
        end
    end
    Base.show(s::StepDriver, io::Core.IO = stdout) = print(io, string(s))
    Base.string(s::StepDriver) = string("state:", string(s.state), "\n", string(s.succ))




















    # abstract type LabelledTransition end

    # # represents individual action
    # struct LocalStep <: LabelledTransition
    #     succ::Configuration
    #     action::Action
    #     state::Configuration
    #     label()=action.label
    #     function LocalStep(state::Configuration,interaction::Interaction) 
    #         val=state.valuations

    #         # action?
    #         if typeof(interaction)==ActionType

    #         elseif typeof(interaction)==RecursionType
    #             # recursion?
    #         elseif typeof(interaction)==End
    #             # term
    #         else
    #             @error "LocalStep: unknown typeof ($(typeof(interaction)))"
    #         end

    #         new(~,~,Action(interaction),state)
    #     end
    # end
    # Base.show(l::LocalStep, io::Core.IO = stdout) = print(io,string(l))
    # Base.string(l::LocalStep) = string(string(l.succ), "\n\n", string(l.action), "\n\n", string(l.state))


    # # get all local steps from current config
    # mutable struct LocalSteps
    #     state::Configuration
    #     children::Array{LocalStep}
    #     function LocalSteps(state::Configuration) 
    #         val=state.valuations
    #         t=state.type

    #         if typeof(t)==Choice

    #         elseif type(t)==Interaction
                
    #         elseif type(t)==Def
                
    #         elseif type(t)==Call
                
    #         elseif type(t)==End
                
    #         end

    #         new(state,[])
    #     end
    # end
    # Base.show(l::LocalSteps, io::Core.IO = stdout) = print(io,string(l))
    # Base.string(l::LocalSteps) = string(join([string(s) for s in l.children],"\n"))

    # Base.string(l::Array{LocalStep}) = string(join([string(s) for s in l],"\n"))

end