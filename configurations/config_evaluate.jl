module ConfigurationEvaluations

    import Base.show
    import Base.string
    
    import Base.length
    import Base.isempty

    import Base.push!
    import Base.getindex
    import Base.iterate

    using ...LogicalClocks
    using ...SessionTypes

    using ..LocalConfigurations
    using ..SocialConfigurations
    # using ..SystemConfigurations

    export Evaluate!

    "Determines if the given Configuration is Enabled (can make a step)."
    struct Evaluate!
        valuations::ν
        type::T where {T<:SessionType}
        #
        eval_en::δEvaluation!
        eval_fe::δEvaluation!
        #
        actionable::Bool
        enabled::Q where {Q<:Union{Nothing,Bool}}
        future_en::R where {R<:Union{Nothing,Bool}}
        #
        interact_en::Array{Interact}
        interact_fe::Array{Interact}
        #
        # local evaluation
        function Evaluate!(c::Local) 
            # update valuations from Evaluate!
            evaluation = Evaluate!(c.valuations,c.type)
            c.valuations = evaluation.valuations
            return evaluation
        end
        # social evaluation
        function Evaluate!(c::Social) 
            # update valuations from Evaluate!
            evaluation = Evaluate!(c.valuations,c.type)
            c.valuations = evaluation.valuations
            return evaluation
        end
        # 
        function Evaluate!(v::ν,t::T) where {T<:SessionType}
            
            interact_en = Array{Interact}([])
            interact_fe = Array{Interact}([])

            if t isa Choice
        
                _actionable=true
                # for interact in choice
                _evals = Array{Evaluate!}([])
                for i in t
                    _eval = Evaluate!(v,i)
                    push!(_evals, _eval)
                    # add to list of enabled actions
                    if _eval.enabled
                        push!(interact_en,i)
                        push!(interact_fe,i)
                    elseif _eval.future_en
                        push!(interact_fe,i)
                    end

                end
               
                _en = true ∈ [i.enabled for i in _evals]
                _fe = true ∈ [i.future_en for i in _evals]

                _eval_en = δEvaluation!(Array{δEvaluation!}([i.eval_en for i in _evals]))
                _eval_fe = δEvaluation!(Array{δEvaluation!}([i.eval_fe for i in _evals]))

            elseif t isa Interact

                _actionable=true

                # @debug "Evaluate!, en: $(string(t.constraints))."

                # ? is enabled
                _eval_en = δEvaluation!(v,t.constraints)
                # @debug "Evaluate!, en eval: $(string(_eval_en))."
                _result_en = eval(_eval_en.expr)
                
                _en = string(_result_en)=="true"

                @assert string(_result_en) in ["true","false"] "Evaluate!, unexpected result (en): $(string(_result_en))\n\tof δEvaluation!: $(string(_eval_en))"

                # ? is future enabled
                past = δ⬇(t.constraints;normalise=true)

                # @debug "Evaluate!, past: $(string(past))."

                _eval_fe = δEvaluation!(v, past.past)
                # @debug "Evaluate!, past eval: $(string(_eval_fe))."
                _result_fe = eval(_eval_fe.expr)
                
                _fe = string(_result_fe)=="true"

                # add to list of enabled actions
                if _en
                    push!(interact_en,t)
                    push!(interact_fe,t)
                elseif _fe
                    push!(interact_fe,t)
                end

                @assert string(_result_fe) in ["true","false"] "Evaluate!, unexpected result (fe): $(string(_result_fe))\n\tof δEvaluation!: $(string(_eval_fe))"

            elseif t isa μ
                _actionable=true
                _en=nothing
                _fe=nothing
                # default if not actionable
                _eval_en = δEvaluation!(:tt)
                _eval_fe = δEvaluation!(:tt)

            elseif t isa α
                _actionable=false
                _en=nothing
                _fe=nothing
                # default if not actionable
                _eval_en = δEvaluation!(:tt)
                _eval_fe = δEvaluation!(:tt)

            elseif t isa End
                _actionable=false
                _en=nothing
                _fe=nothing
                # default if not actionable
                _eval_en = δEvaluation!(:tt)
                _eval_fe = δEvaluation!(:tt)

            else
                @error "Evaluate!, unexpected typein Local.type: $(typeof(t))"
            end

            new(v,t,_eval_en,_eval_fe,_actionable,_en,_fe,interact_en,interact_fe)
        end
    end

    Base.show(e::Evaluate!, io::Core.IO = stdout) = print(io, string(e))
    Base.show(e::Evaluate!, mode::Symbol, io::Core.IO = stdout) = print(io, string(e,mode))
    Base.show(e::Evaluate!, modes::T, io::Core.IO = stdout) where {T<:Array{Symbol}}= print(io, string(e,modes...))

    function Base.string(e::Evaluate!, args...)
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end
        if length(args) < 2
            second_mode=:not_given
        else
            second_mode=args[2]
        end

        if mode==:full
            # display config and attributes

            if second_mode==:expand
                # also display enabled/fe actions
                return string(
                    "\nconfiguration, actionable: ", string(e.actionable), "\n", string(Local(e.valuations,e.type),args...,:str),
                    "\nenabled: ", string(e.enabled), "\n$(string(e.eval_en, :expand))...",
                    "\n\t$(string(join([string(i) for i in e.interact_en], "\n\t")))",
                    "\nfuture enabled: ", string(e.future_en), "\n$(string(e.eval_fe, :expand))...",
                    "\n\t$(string(join([string(i) for i in e.interact_fe], "\n\t"))).",
                )

            else
                # display summary enabled/fe actions
                return string(
                    "\nconfiguration, actionable: ", string(e.actionable), "\n", string(Local(e.valuations,e.type),args...,:str),
                    "\nenabled: ", string(e.enabled),
                    "\nfuture enabled: ", string(e.future_en)
                )

            end

        elseif mode==:default
            # display attributes only
            return string(
                "actionable: ", string(e.actionable),
                "\nenabled: ", string(e.enabled),
                "\nfuture enabled: ", string(e.future_en)
            )
        
        else
            @warn "string.Evaluate!, unexpected mode: $(string(args))."
            
        end


    end

end