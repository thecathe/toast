module Configurations

    import Base.show
    import Base.string
    import Base.convert
    import Base.iterate
    
    using ..General
    using ..LogicalClocks
    using ..ClockConstraints
    using ..SessionTypes
    using ..ClockValuations


    # configurations

    abstract type Configuration end

    struct Local <: Configuration
        valuations::Valuations
        type::T where {T<:SessionType}
        function Local(valuations,type)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"
            new(valuations,type)
        end
    end
    Base.show(c::Local, io::Core.IO = stdout) = string(io, c)
    function Base.string(c::Local, verbose::Bool = false)
        string("(", join([string(c.clocks, verbose),string(c.type, verbose)],", "), ")")
    end
    

    struct Social <: Configuration
        valuations::Valuations
        type::T where {T<:SessionType}
        queue::Msgs
        function Social(clocks,type,queue)
            @assert typeof(type) == S "initially type ($(typeof(type))) must be $(string(typeof(S)))"
            new(clocks,type,queue)
        end
    end
    Base.show(c::Social, io::Core.IO = stdout) = string(io, c)
    function Base.string(c::Local, verbose::Bool = false)
        string("(", join([string(c.clocks, verbose),string(c.type, verbose),string(c.queue, verbose)],", "), ")")
    end

    # from social to local configurations
    Base.convert(::Type{Local}, c::T) where {T<:Social} = Local(c.valuations,c.type)

    
    isend(c::Local) = (typeof(c.type) == End) ? true : false
    isend(c::Social) = (typeof(c.type) == End) ? true : false


    # struct Scope{T} where {T<:Configuration} 
    #     value::T
    #     Scope{T}(::Type{T}) where {T<:Configuration} = new(T)
    # end

    abstract type LabelledTransition end

    # represents individual action
    struct LocalStep <: LabelledTransition
        succ::Configuration
        action::Action
        state::Configuration
        label()=action.label
        function LocalStep(state::Configuration,interaction::Interaction) 
            val=state.valuations

            # action?
            if typeof(interaction)==ActionType

            elseif typeof(interaction)==RecursionType
                # recursion?
            elseif typeof(interaction)==End
                # term
            else
                @error "LocalStep: unknown typeof ($(typeof(interaction)))"
            end

            new(~,~,Action(interaction),state)
        end
    end

    _c = Clocks([("a",1)])
    _v = Valuations(_c)
    _s = S(Choice([(:send, Msg("a", Int), δ(:not,δ(:geq,"x",3)),[], Def("a", (:send, Msg("b", String), δ(:tt), [], Call("a")))),(:recv, Msg("c", Bool), δ(:geq,"y",3),[])]))
    _l = Local(_v,_s)



    # get all local steps from current config
    mutable struct LocalSteps
        state::Configuration
        children::Array{LocalStep}
        function LocalSteps(state::Configuration) 
            val=state.valuations
            new(state,[])
        end
    end

    show(_l)
    show(_step = LocalSteps(_l))

    # struct LocalStep


    
    # struct Step{T} where {T<:Configuration} 
    #     succ::Scope{T}
    #     label::Label
    #     scope::Scope{T}
    #     function Step{T}(scope,label) 
    #         if typeof(scope.type)==Choice
    #             _succ = nothing
    #         elseif typeof(scope.type)==Interaction
    #             _succ = nothing
    #         end
    #         new(scope,label,_succ)
    #     end
    # end

    
    # struct Steps{T} where {T<:Configuration} 
    #     children::Array{Step{T}}
    #     Steps{T}() = new(Array{Step{T}})
    # end

    # mutable struct Steps{Local} <: LabelledTransition
    #     children::Array{Step{Local}}
    #     Steps{Local}(children) = new(children)
    # end


    # # Base.getindex(c::Local, i::Int)
    # function step(c::Local)
    #     if isend(c)
    #         return 
    # end

    # Base.iterate(c::Local) = isend(c) ? nothing : (c[1], Int(1))


    # Base.iterate(c::Clocks) = isempty(c) ? nothing : (c[1], Int(1))
    # Base.iterate(c::Clocks, i::Int) = (i >= length(c)) ? nothing : (c[i+1], i+1)

    # Base.iterate(c::Social) = isend(c) ? nothing : (c[])
    
    struct System <: Configuration
        lhs::Social
        rhs::Social
        System(lhs,rhs) = new(lhs,rhs)
    end
    Base.show(c::System, io::Core.IO = stdout) = string(io, c)
    function Base.string(c::System, verbose::Bool = false)
        string("(", join([string(c.lhs,verbose),string(c.rhs,verbose)]," ∣ "), ")")
    end

    # 

end