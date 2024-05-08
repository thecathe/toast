module WellformednessJudgements

    import Base.show
    import Base.string

    using ..LogicalClocks
    using ..SessionTypes
    using ..RecVarEnv
    
    export WfJudgement
    mutable struct WfJudgement
        vars::RecEnv
        constraints::δ
        type::T where {T<:SessionType}
        WfJudgement(vars::RecEnv,constraints::δ,type::T) where {T<:SessionType} = new(vars,constraints,type)
    end

    Base.string(j::WfJudgement, args...) = "$(string(j.vars)); $(string(j.constraints)) ⊢ $(string(j.type))"

end