module WellformednessRules

    import Base.show
    import Base.string

    using ..LogicalClocks
    using ..SessionTypes
    using ..Configurations
    using ..Transitions

    export WellformednessRule
    abstract type WellformednessRule end

    export IsWellformed

    include("rules/wellformedness/rec_var_env.jl")
    using .RecVarEnv
    export RecEnv

    include("rules/judgements/wellformedness.jl")
    using .WellformednessJudgements
    export WfJudgement

    include("rules/premise.jl")
    using .RulePremise
    export Premise, Premises, evaluate

    #
    # well-formedness rules
    #
    include("rules/wellformedness/rule_end.jl")
    using .WellformednessRuleEnd
    export WfRuleEnd

    include("rules/wellformedness/rule_var.jl")
    using .WellformednessRuleVar
    export WfRuleVar

    include("rules/wellformedness/rule_rec.jl")
    using .WellformednessRuleRec
    export WfRuleRec

    include("rules/wellformedness/rule_choice.jl")
    using .WellformednessRuleChoice
    export WfRuleChoice

    #
    # handles checking well-formedness of any types
    #
    struct IsWellformed <: WellformednessRule

        judgement::WfJudgement
        premises::Premises
        evaluation::Bool
        rule::String

        # end type
        function IsWellformed(type::End,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([])) 
            rule = WfRuleEnd(type,constraints,vars;rec_flags)
            new(rule.judgement,rule.premises,rule.evaluation,rule.label)
        end

        # var type
        function IsWellformed(type::α,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([])) 
            rule = WfRuleVar(type,constraints,vars;rec_flags)
            new(rule.judgement,rule.premises,rule.evaluation,rule.label)
        end

        # rec type
        function IsWellformed(type::μ,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([])) 
            rule = WfRuleRec(type,constraints,vars;rec_flags)
            new(rule.judgement,rule.premises,rule.evaluation,rule.label)
        end

        # interact/choice type
        function IsWellformed(type::T,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([])) where {T<:Union{Interact,Choice}}
            rule = WfRuleChoice(type,constraints,vars;rec_flags)
            new(rule.judgement,rule.premises,rule.evaluation,rule.label)
        end

        # # unknown? figure it out
        # function IsWellformed(type::T;constraints::δ=δ(:tt),vars::RecEnv=RecEnv()) where {T<:SessionType} 
        #     rule_end = WfRuleEnd(type;constraints,vars)
        #     new(rule_end.judgement,rule_end.premises,rule_end.evaluation)
        # end
    end

 
    Base.show(d::IsWellformed, io::Core.IO = stdout) = print(io, string(d))
    Base.show(d::IsWellformed, mode::Symbol, io::Core.IO = stdout) = print(io, string(d, mode))

    function Base.string(wf::IsWellformed, args...) 
        # get mode
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        if mode==:default
            # start building array
            arr = Array{String}([])
            width = 0
            # add each premise as a row from the top
            for p in wf.premises
                # check if another rule or a condition
                if p.condition isa Expr
                    p_str = "$(p.label) = $(string(eval(p.condition.expr)))"
                    push!(arr,p_str)
                elseif p.condition isa WellformednessRule
                    p_arr = string(p.condition,:default,:arr)
                    p_width = 0
                    p_label_width = length(string(p.condition,:label))
                    p_str = ""
                    for p_str_line in p_arr
                        push!(arr,p_str_line)
                        # update p_width
                        if length(p_str_line)-p_label_width>p_width 
                            p_width = length(p_str_line)-p_label_width
                            p_str= repeat(" ", p_width)
                        end
                    end
                end
                # update width
                if length(p_str)>width 
                    width = length(p_str)
                end
            end
            # judgement string
            j_str = string(wf.judgement)
            # if no premises (such as rule end) still have line
            if length(arr)==0
                push!(arr,"")
                width = length(j_str)
            else
                width = max(width,length(j_str))
            end
            # draw divider between premises and judgement
            div_str = "$(repeat("-",width)) $(string(wf,:label))"
            push!(arr,div_str)
            push!(arr,j_str)

            if :arr ∈ args
                return arr
            else
                return string(join(arr,"\n"))
            end
        elseif mode==:label
            return "[$(wf.rule)] $(wf.evaluation ? "⊤" : "⊥")"
        else
            @error "IsWellformed.string, unexpected mode: $(string(mode))."
        end
    end
    

end