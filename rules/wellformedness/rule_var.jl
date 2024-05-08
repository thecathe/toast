module WellformednessRuleVar

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    using ...Configurations
    using ...WellformednessRules

    export WfRuleVar
    struct WfRuleVar <: WellformednessRule

        label::String
        judgement::WfJudgement
        premises::Premises
        evaluation::Bool

        function WfRuleVar(type::α,constraints::δ,vars::RecEnv;rec_flags::Array{α}=Array{α}([]))
            # assign any rec_flags to constraints
            new_vars = deepcopy(vars)
            for rec in rec_flags
                new_vars[rec] = constraints
            end
            judgement = WfJudgement(new_vars,constraints,type)
            premises = Premises()
            #
            correct_type = type isa α
            var_defined = type ∈ new_vars
            # fetch from rec var env
            var_constraints = get(new_vars, type, false)
            if var_constraints isa Bool
                @assert !var_defined "WfRuleVar, var ($(string(type))) was not found in vars ($(string(vars))) even though \"type∈vars\" passed."
            end
            # TODO still need to check below
            constraints_satisfied = true
            @warn "WfRuleVar, still need to finish \"constraints_satisfied\" (checking if '$(string(var_constraints)))' are satisfied by '$(string(constraints))'"
            # evaluation is success if all hold
            success = correct_type && var_defined && constraints_satisfied
            new("Var",judgement,premises,success)
        end

    end
end