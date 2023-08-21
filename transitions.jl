module Transitions

    
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