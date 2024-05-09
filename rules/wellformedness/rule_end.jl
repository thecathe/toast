module WellformednessRuleEnd

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations
    using ...WellformednessRules

    export WfRuleEnd
    struct WfRuleEnd <: WellformednessRule

        label::String
        judgement::WfJudgement
        premises::Premises
        evaluation::Bool

        function WfRuleEnd(type::End,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([]))
            # assign any rec_flags to constraints
            new_vars = deepcopy(vars)
            for rec in rec_flags
                new_vars[rec] = constraints
            end
            # constraints always hold (==true)
            judgement = WfJudgement(new_vars,constraints,type)
            premises = Premises(:wf,:end)
            success = type isa End && premises.hold
            new("End",judgement,premises,success)
        end

    end
end