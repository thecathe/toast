module RulePremise

    import Base.show
    import Base.string

    import Base.length
    import Base.isempty
    
    import Base.getindex
    import Base.iterate

    import Base.get
    import Base.findall

    using ..WellformednessRules

    export Premise
    struct Premise
        label::Union{Nothing,String}
        condition::T where {T<:Union{Expr,R} where {R<:WellformednessRule}}
        is_expr::Bool
        has_label::Bool
        Premise(label::String,expr::Expr) = new(label,expr,true,true)
        Premise(label::String,condition::WellformednessRule) = new(label,condition,false,true)
        Premise(expr::Expr) = new(nothing,expr,true,false)
        Premise(condition::WellformednessRule) = new(nothing,condition,false,false)
    end

    Base.show(p::Premise, io::Core.IO = stdout) = print(io, string(p))
    Base.show(p::Premise, mode::Symbol, io::Core.IO = stdout) = print(io, string(p, mode))
    
    Base.string(p::Premise, args...) = "$(string(p.condition)) $(p.is_expr&&p.has_label ? p.label : "")"


    
    export Premises
    mutable struct Premises
        children::Array{Premise}
        # empty case
        Premises() = new(Array{Premise}([]))
        # single case
        Premises(p::Premise) = new(Array{Premise}([p]))
        Premises(ps::Array{Premise}) = new(ps)
        # anonymous list case
        # Premises(ps::Array{ET}) where {T<:Expr} = Array{Premise}([Premise(p) for p in ps])
    end

    Base.show(ps::Premises, io::Core.IO = stdout) = print(io, string(ps))
    Base.show(ps::Premises, mode::Symbol, io::Core.IO = stdout) = print(io, string(ps, mode))
    
    Base.string(ps::Premises, args...) = string(join([string(p) for p in ps],"\n"))

    Base.length(ps::Premises) = length(ps.children)
    Base.isempty(ps::Premises) = isempty(ps.children)
    Base.getindex(ps::Premises, i::Int) = getindex(ps.children, i)

    Base.iterate(ps::Premises) = isempty(ps) ? nothing : (ps[1], Int(1))
    Base.iterate(ps::Premises, i::Int) = (i >= length(ps)) ? nothing : (ps[i+1], i+1)

    "Get premise with matching label."
    function Base.get(ps::Premises,label::String,default=nothing)
        for premise in ps
            if premise.label==label 
                return premise
            end
        end
        return default
    end

    "Findall premises that evaluate to val."
    function Base.findall(ps::Premises,val::Bool)
        collection = Array{Premise}([])
        for premise in ps
            if eval(premise.expr)==val
                push!(collection,premise)
            end
        end
        return collection
    end


    export evaluate
    function evaluate(p::Premise)
        if p.condition isa Expr
            return evaluate(p.condition)
        elseif p.condition isa WellformednessRule
            return p.condition.evaluation
        else
            @error "Premise.evaluate, unexpected premise isa $(typeof(p)),\n$(string(p))."
        end
    end

    function evaluate(ps::Premises)
        result = true
        for premise in ps
            result = result && evaluate(premise)
        end
        return result
    end



end