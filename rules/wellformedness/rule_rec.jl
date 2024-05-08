module WellformednessRuleRec

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations
    using ...WellformednessRules

    export WfRuleRec
    struct WfRuleRec <: WellformednessRule

        label::String
        judgement::WfJudgement
        premises::Premises
        evaluation::Bool

        function WfRuleRec(type::μ,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([]))
            # add current ref to rec_flags for the next type to resolve
            rec_call = α(type)
            push!(rec_flags,rec_call)

            # evaluate premise with current constraints
            premise = IsWellformed(type.child,constraints,vars;rec_flags)
            premises = Premises(Premise(premise))

            new_constraints = deepcopy(premise.judgement.constraints)
            @assert new_constraints isa δ "WfRuleRec, premise isa $(typeof(new_constraints)), when expected δ."

            judgement = WfJudgement(vars,new_constraints,type)

            # evaluation holds if premises hold
            evaluation = evaluate(premises)

            new("Rec",judgement,premises,evaluation)
        end
    end
end