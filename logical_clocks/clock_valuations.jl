module ClockValuations

    import Base.show
    import Base.string

    using ..LogicalClocks

    export ν, ValueOf!, ResetClocks!, TimeStep!, init!

    mutable struct ν
        clocks::Array{Clock}
        system::Clock
        #
        ν(children::T,offset::Num = 0) where {T<:Array{Clock}} = new(children,Clock("𝒢",UInt8(offset)))
        # empty
        ν(offset::Num = 0) = ν(Array{Clock}([]),offset)
        # single
        ν(child::Clock) = ν(Array{Clock}([child]))
        # anonymous clock
        ν(child::T,offset::Num = 0) where {T<:Tuple{String,Num}} = ν(Array{Clock}([Clock(child...)]), offset)
        # anonymous clocks
        ν(children::Array{T},offset::Num = 0) where {T<:Tuple{String,Num}} = ν(Array{Clock}([Clock(c...) for c in children]), offset)
    end

    Base.show(t::ν, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::ν, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::ν, args...)
        arg_len = length(args)
        if arg_len==0
            mode = :default
        else
            @assert args[1] isa Symbol
            mode = args[1]
        end

        if mode==:default
            string(join([string(v) for v ∈ [t.system,t.clocks...]], ", "))
        
        elseif mode==:system
            # :system - just return system
            return string(string(t.system))
        
        elseif mode==:full
            # :full - array of each line
            str_children = Array{String}([string(t.system,:default), "", [string(c,:default) for c in t.clocks]...])
            widest_child = maximum(length, str_children)
            num_children = length(str_children)
            
            arr_build = Array{String}([])
            for y in 1:num_children
                # pad current child
                curr = str_children[y]
                push!(arr_build,string(curr, repeat(" ", widest_child - length(curr))))
            end

            # how to return? (default: arr)
            if arg_len>1
                second_mode = args[2]
            else
                second_mode = :arr
            end
            if second_mode==:arr
                return arr_build
            elseif second_mode==:str
                return string(join(arr_build), "\n")
            else
                @error "ν.string, unexpected second mode: $(string(args))"
            end

        elseif mode==:smart
            # :smart - next arg is list of clocks to include (always include system)
            @assert length(args)==2 "ν.string, mode :smart expects two parameters"
            @assert args[2] isa Array{String} "ν.string, mode :smart expects Array{String}, not: $(typeof(args[2]))"

            relevant_labels = Array{String}([args[2]...])

            relevant_clocks = Array{Clock}([filter(x->(x.label in relevant_labels), t.clocks)...])
            str_clocks = Array{String}([string(t.system,:default), "", [string(x,:default) for x in relevant_clocks]...])
            num_relevant = length(str_clocks)

            widest_child = maximum(length, str_clocks)
            
            arr_build = Array{String}([])
            for y in 1:num_relevant
                # pad current child
                curr = str_clocks[y]
                push!(arr_build,string(curr, repeat(" ", widest_child - length(curr))))
            end

            # how to return? (default: arr)
            if arg_len>2
                second_mode = args[3]
            else
                second_mode = :arr
            end
            if second_mode==:arr
                return arr_build
            elseif second_mode==:str
                return string(join(arr_build), "\n")
            else
                @error "ν.string, unexpected second mode: $(string(args))"
            end

        else
            @error "TimeStep!.string, unexpected mode: $(string(t))"
        end
    end

    """
    function init!(clock_label::String, valuations::ν)
        instansiates a clock with given label and value of system clock, if it does not already exist
    """
    function init!(c::String,v::ν)
        if c ∉ [x.label for x in v.clocks]
            push!(v.clocks, Clock(c,v.system.value))
        end
    end

    #
    # value
    #
    struct ValueOf!
        label::String
        value::Num

        function ValueOf!(v::ν,label::String) 
            for c ∈ v.clocks
                if c.label==label
                    return new(label,c.value)
                end
            end
            
            # new clock
            push!(v.clocks,Clock(label,0))
            new(label,0)
        end
    end

    Base.show(t::ValueOf!, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::ValueOf!, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::ValueOf!, mode::Symbol = :default)
        if mode==:default
            string("($(string(t.label)):$(string(t.value)))")
        else
            @error "ValueOf!.string, unexpected mode: $(string(t))"
        end
    end

    #
    # resets
    #
    struct ResetClocks!
        resets::λ
        #
        ResetClocks!(v::ν,label::String) = ResetClocks!(v,Array{String}([label]))
        #
        ResetClocks!(v::ν,resets::T) where {T<:Array{String}} = ResetClocks!(v,λ(resets))
        #
        function ResetClocks!(v::ν,resets::λ)
            reset = Array{String}([])
            for c ∈ v.clocks
                if c.label ∈ resets
                    c.value = 0
                    push!(reset,c.label)
                end
            end
            # check for non-existant clocks
            for l ∈ resets
                if l ∉ reset
                    push!(v.clocks,Clock(l,v.system.value))
                end
            end
            new(resets)
        end
    end

    Base.show(t::ResetClocks!, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::ResetClocks!, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::ResetClocks!, mode::Symbol = :default)
        if mode==:default
            string("[{$(join([string(r) for r in t.resets],","))}↦ 0]")
        else
            @error "ResetClocks!.string, unexpected mode: $(string(t))"
        end
    end

    #
    # time step
    #
    struct TimeStep!
        value::Num
        #
        function TimeStep!(v::ν,t::Num) 
            foreach(x -> x.value += t, v.clocks)
            v.system.value += t
            new(t)
        end
    end
    
    Base.show(t::TimeStep!, io::Core.IO = stdout) = print(io, string(t))
    Base.show(t::TimeStep!, mode::Symbol, io::Core.IO = stdout) = print(io, string(t, mode))

    function Base.string(t::TimeStep!, mode::Symbol = :default)
        if mode==:default
            string("(t=$(string(t.value)))⟶")
        else
            @error "TimeStep!.string, unexpected mode: $(string(t))"
        end
    end
end