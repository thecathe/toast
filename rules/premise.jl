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
    using ...SessionTypes
    using ...LogicalClocks

    # const supported_premise_types = [:axiom,:eval] end

    # struct PremiseComponent

    # end

    export Premise
    struct Premise

        is_axiom::Bool
        has_nested_eval::Bool
        label::Union{Nothing,String}
        holds::Bool
        eval_string::String
        theory_string::String
        nested_eval::Union{Nothing,T} where {T<:WellformednessRule}

        function Premise(kind::Symbol) 
            @assert kind==:axiom "Premise, when given only a symbol, that symbol is expected to be :axiom, not $(string(kind))."
            new(true,false,nothing,true,"","",nothing)
        end

        function Premise(kind::Symbol,scope::Symbol,args...)
            if kind==:wf
                if scope∈[:end,:var] 
                    return Premise(:axiom)
                elseif scope==:choice
                    # remove symbol from front of args
                    premise_line = pop!(args, 1)
                    if premise_line==:feasibility
                        return get_wf_choice_feasibility(args...)
                    elseif premise_line==:mixed_choice
                        return get_wf_choice_mixed_choice(args...)
                    elseif premise_line==:delegation
                        return get_wf_choice_delegation(args...)
                    else
                        @error "Premise:wf:choice, unexpected premise line ($(string(premise_line)))."
                    end
                elseif scope==:rec
                    @assert args[1] isa RecEnv "Premise:rec expects args[1] to be RecEnv, not($(string(typeof(args[1]))))."
                    @assert args[2] isa δ "Premise:rec expects args[2] to be δ, not($(string(typeof(args[2]))))."
                    @assert args[3] isa μ "Premise:rec expects args[3] to be μ, not($(string(typeof(args[3]))))."
                    return get_wf_rec(args[1],args[2],args[3])
                end
            else
                @error "Premise, unexpected kind ($(string(kind)))."
            end
        end

        function get_wf_choice_feasibility(vars::RecEnv,constraints::δ,type::T) where {T<:Union{Interact,Choice}}
            is_axiom = false
            has_nested_eval = true
            nested_eval = nothing # default
            label = "feasibility"
            holds = false # default
            theory_string = "∀i∈I: A;γᵢ⊢Sᵢ ∧ δᵢ[λᵢ↦0]⊨γᵢ"

            # work out if premise holds and make eval_string

            eval_string = "?"

            new(is_axiom,has_nested_eval,label,holds,eval_string,theory_string,nested_eval)
        end

        function get_wf_choice_mixed_choice(vars::RecEnv,constraints::δ,type::T) where {T<:Union{Interact,Choice}}
            is_axiom = false
            has_nested_eval = false
            nested_eval = nothing 
            label = "mixed-choice"
            holds = false # default
            theory_string = "∀i,j∈I: i≠j ⟹ δᵢ∧δⱼ⊨false ∨ □ᵢ=□ⱼ"

            # work out if premise holds and make eval_string
            if type isa Interact
                num_I == 1
            elseif type isa Choice
                num_I = length(type)
            end
            # if only one interaction, then passes by default
            if num_I==1
                holds = true
                eval_string = "(only one interaction in choice)"
            else
                problematic_pairs = Array{Tuple{UInt8,UInt8,Dict{String,Array{Tuple{δ,δ}}}}}([])
                # follow theory
                for i in 1:num_I
                    for j in 1:num_I
                        if i≠j
                            # check if deltas overlap
                            i_delta = type[i].constraints
                            j_delta = type[j].constraints
                            constraints_overlap = false

                            # get bounds of each
                            i_bounds = δBounds(i_delta;normalise=true)
                            j_bounds = δBounds(j_delta;normalise=true)
                            # only want clocks that are in both
                            all_clocks = unique([i_bounds.clocks...,j_bounds.clocks...])
                            relavent_clocks = [c for c in all_clocks if c∈i_bounds.clocks && c∈j_bounds.clocks ]
                            # go through each, check if any of the bounds overlap
                            overlapping_constraints = Dict{String,Array{Tuple{δ,δ}}}([])
                            for c in relavent_clocks
                                i_c = i_bounds.bounds[c]
                                j_c = j_bounds.bounds[c]
                                # for each bound on clock c in i
                                for i_b in i_c
                                    # for each bound on clock c in j
                                    for j_b in j_c
                                        # TODO :: check if their bounds overlap
                                    end
                                end
                            end



                            # check if directions are the same
                            i_comm = type[i].direction.dir
                            j_comm = type[j].direction.dir
                            comm_matches = i_comm==j_comm

                            # mark as problematic if neither hold
                            if comm_matches || constraints_overlap
                                push!(problematic_pairs, (i, j, overlapping_constraints))
                            end
                        end
                    end
                end
                holds = length(problematic_pairs)==0
                # build eval string with only eval
                arr = Array{String}([])
                for p in problematic_pairs
                    i = p[1]
                    j = p[1]
                    p_str = "i:$(string(i))≠j:$(string(j)) ⟹ "
                    i_str = string(type[i])
                    j_str = string(type[j])
                    p_str = "$(p_str) $(i_str)\n$(repeat(" ",length(p_str))) $(j_str)"
                    push!(arr,p_str)
                end
                eval_string = join(arr, "\n")
            end

            new(is_axiom,has_nested_eval,label,holds,eval_string,theory_string,nested_eval)
        end

        function get_wf_choice_delegation(vars::RecEnv,constraints::δ,type::T) where {T<:Union{Interact,Choice}}
            is_axiom = false
            has_nested_eval = true
            nested_eval = nothing # default
            label = "delegation"
            holds = false # default
            theory_string = "∀i∈I: Tᵢ=(δ′,S′) ⟹ ∅;γ′⊢S′ ∧ δ′⊨γ′"

            eval_string = "?"

            new(is_axiom,has_nested_eval,label,holds,eval_string,theory_string,nested_eval)
        end

        function get_wf_rec(vars::RecEnv,constraints::δ,type::μ)
            is_axiom = false
            has_nested_eval = true
            nested_eval = nothing # default
            label = nothing
            holds = false # default
            theory_string = "A,α:δ;δ⊢S"

            eval_string = "?"

            new(is_axiom,has_nested_eval,label,holds,eval_string,theory_string,nested_eval)
        end

        # Premise(:master_preset)
    end

    Base.show(p::Premise, io::Core.IO = stdout) = print(io, string(p))
    Base.show(p::Premise, mode::Symbol, io::Core.IO = stdout) = print(io, string(p, mode))
    
    function Base.string(p::Premise, args...) 
        # by default print theory (?)
        if length(args)==0 
            return "$(p.theory_string)$(p.label≠nothing ? " ($(p.label))" : "")$(p.holds ? " ✖" : "" )"
        elseif :theory ∈ args
            return "$(p.theory_string)$(p.label≠nothing ? " ($(p.label))" : "")$(p.holds ? " ✖" : "" )"
        else
            return "$(p.eval_string)$(p.label≠nothing ? " ($(p.label))" : "")$(p.holds ? " ✖" : "" )"
        end
    end

    
    export Premises
    mutable struct Premises
        children::Array{Premise}
        hold::Bool

        # wrapper function just to determine if premise holds
        function Premises(kind::Symbol,premises::Array{Premise}) 
            @assert kind==:check_hold "Premises, when given only a symbol and Array{Premise}, that symbol is expected to be :check_hold, not $(string(kind))."
            holds = false ∉ [p.holds for p in premises] # always holds
            new(premises,holds)
        end

        function Premises(kind::Symbol,scope::Symbol;vars::Union{Nothing,RecEnv}=nothing,constraints::Union{Nothing,δ}=nothing,type::Union{Nothing,T}=nothing) where {T<:SessionType}
            if kind==:wf
                # rules [end] and [var] are axioms
                if scope∈[:end,:var]
                    return Premises(:check_hold,Array{Premise}([Premise(:axiom)]))
                elseif scope==:choice
                    # rule [choice] has 3 premises
                    f = Premise(:wf,:choice,:feasibility,vars,constraints,type)
                    m = Premise(:wf,:choice,:mixed_choice,vars,constraints,type)
                    d = Premise(:wf,:choice,:delegation,vars,constraints,type)
                    return Premises(:check_hold,Array{Premise}([f,m,d]))
                elseif scope==:rec
                    # rule [rec] has only one premise
                    p = Premise(:wf,:rec,vars,constraints,type)
                    return Premises(:check_hold,Array{Premise}([p]))
                else 
                    @error "Premises:wf, unexpected scope: $(string(scope))."
                end
            else
                @error "Premises, unexpected kind: $(string(kind))."
            end
        end

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