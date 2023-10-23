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

    struct Evaluate!
        valuations::Valuations
        type::T where {T<:SessionType}
        #
        eval_en::δEvaluation!
        eval_fe::δEvaluation!
        #
        actionable::Bool
        enabled::Q where {Q<:Union{Nothing,Bool}}
        future_en::R where {R<:Union{Nothing,Bool}}
        # local evaluation
        Evaluate!(c::Local) = Evaluate!(c.valuations,c.type)
        # social evaluation
        Evaluate!(c::Social) = Evaluate!(c.valuations,c.type)
        # 
        function Evaluate!(v::Valuations,t::T) where {T<:SessionType}
            
            if t isa Choice

                # println("config.evaluate: choice START")

                _actionable=true
                # for interact in choice
                _evals = Array{Evaluate!}([])
                for i in t
                    push!(_evals, Evaluate!(v,i))
                end
               
                _en = true ∈ [i.enabled for i in _evals]
                _fe = true ∈ [i.future_en for i in _evals]

                # println("config.evaluate: choice NEXT")

                # _choice_constraints = Array{δ}([i.constraints for i in t])
                # _eval = δEvaluation!(v, δ(:disjunct, _choice_constraints))

                _eval_en = δEvaluation!(Array{δEvaluation!}([i.eval_en for i in _evals]))
                _eval_fe = δEvaluation!(Array{δEvaluation!}([i.eval_fe for i in _evals]))

                # _eval_fe = δEvaluation!(v, δ(:disjunct, _choice_constraints))

                println(string("\nChoice($(string(length(t)))): $(string(_eval_en))."))
                println(string("\nChoice(fe:$(string(length(t)))): $(string(_eval_fe))."))

                
                # println("config.evaluate: choice POST")

            elseif t isa Interact
                # println("config.evaluate: interact START")

                _actionable=true
                # if t.constraints.head==:flatten
                _constraints=t.constraints
                # else
                #     _constraints=δ(:flatten,t.constraints)
                # end
                _eval_en = δEvaluation!(v,_constraints)
                _result_en = eval(_eval_en.expr)

                @assert string(_result_en) in ["true","false"] "Evaluate!, unexpected result (en): $(string(_result_en))\n\tof δEvaluation!: $(string(_eval_en))"

                # enabled if true
                _en = string(_result_en)=="true"

                # println("config.evaluate: interact NEXT")

                println(string("\nInteract($(string(Action(t)))): $(string(_eval_en))."))

                # future enabled if en, or
                # if string(_result)=="true"
                #     _en=true
                #     _fe=true
                #     # println("config.evaluate: interact EN")

                # else
                #     # println("config.evaluate: interact FE")

                #     _en=false

                    # @info "config.Evaluate, fe: $(string(t.constraints))."

                    # use weakpast to see if fe
                    _eval_fe = δEvaluation!(v, δ(:past,t.constraints))
                    _result_fe = eval(_eval_fe.expr)
                    
                    println(string("\nInteract(fe:$(string(Action(t)))): $(string(_eval_fe))."))

                    @assert string(_result_fe) in ["true","false"] "Evaluate!, unexpected result (fe): $(string(_result_fe))\n\tof δEvaluation!: $(string(_eval_fe))"

                    # fe if true
                    _fe = string(_result_fe)=="true"
                # end
                # println("config.evaluate: interact END")


            elseif t isa Rec
                _actionable=true
                _en=nothing
                _fe=nothing
                # default if not actionable
                _eval_en = δEvaluation!(:tt)
                _eval_fe = δEvaluation!(:tt)

            elseif t isa Call
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

            new(v,t,_eval_en,_eval_fe,_actionable,_en,_fe)
        end
    end

    Base.show(e::Evaluate!, io::Core.IO = stdout) = print(io, string(e))
    Base.show(e::Evaluate!, mode::Symbol, io::Core.IO = stdout) = print(io, string(e,mode))
    Base.show(e::Evaluate!, modes::T, io::Core.IO = stdout) where {T<:Array{Symbol}}= print(io, string(e,modes...))

    function Base.string(e::Evaluate!, args...)

        return string(
            "\nconfiguration:\n", string(Local(e.valuations,e.type),args...),
            "\nactionable: ", string(e.actionable),
            "\nenabled: ", string(e.enabled),
            "\nfuture enabled: ", string(e.future_en)
        )

    end

end