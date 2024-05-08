module WellformednessRuleChoice

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations
    using ...WellformednessRules

    export WfRuleChoice
    struct WfRuleChoice <: WellformednessRule

        label::String
        judgement::WfJudgement
        premises::Premises
        evaluation::Bool

        # function WfRuleChoice(type::Interact,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([]))

        # end

        function WfRuleChoice(type::Choice,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([]))
            # get disjunction over weakpast of all constraints
            #TODO here



            # assign any rec_flags to constraints
            new_vars = deepcopy(vars)
            for rec in rec_flags
                new_vars[rec] = constraints
            end

            # evaluate premise with current constraints
            premise = IsWellformed(type.child,constraints,vars;rec_flags)
            premises = Premises(Premise(premise))

            new_constraints = deepcopy(premise.judgement.constraints)

            judgement = WfJudgement(new_vars,new_constraints,type)

            # evaluation holds if premises hold
            evaluation = evaluate(premises)

            new("Choice",judgement,premises,evaluation)
        end
    end
end