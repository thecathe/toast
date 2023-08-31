module Configurations

    import Base.show
    import Base.string
    import Base.convert
    import Base.iterate
    import Base.isempty
    import Base.length
    
    using ..General
    using ..LogicalClocks
    using ..ClockConstraints
    using ..SessionTypes
    using ..ClockValuations


    export Configuration, Local, Social, System

    # configurations

    abstract type Configuration end

    struct Local <: Configuration
        valuations::Valuations
        # type::T where {T<:SessionType}
        type::S

        Local(valuations::Valuations,type::Dual) = Local(valuations,S(type.child))
        
        function Local(valuations::Valuations,type::S) 
            if type.kind in [:choice,:interaction]
                # populate immediately relevant clocks
                if type.kind==:choice
                    _relevant_clocks = ConstrainedClocks(Constraints([s.δ for s in type.child.children]))
                elseif type.kind==:interaction
                    _relevant_clocks = ConstrainedClocks(Constraints([type.child.δ]))
                end

                for l in _relevant_clocks.labels
                    Value!(valuations, l)
                end
            end
            new(valuations,type)
        end
    end
    Base.show(c::Local, mode::Symbol, io::Core.IO = stdout) = print(io, string(c, mode))
    Base.show(c::Local, io::Core.IO = stdout) = print(io, string(c))
    function Base.string(cfg::Local, mode::Symbol=:default)
        if mode==:default
            return string("( ", join([string(cfg.valuations),string(cfg.type)],", "), ")")
        else
            # arrays for each field
            clock_lines = Array{String}([string(cfg.valuations.system),[string(v) for v in cfg.valuations.clocks]...])

            if mode==:local_full
                if cfg.type.kind==:choice
                    type_lines = Array{String}([string(i,:full) for i in cfg.type.child.children])
                else
                    type_lines = Array{String}([string(cfg.type,:full)])
                end
            else
                if cfg.type.kind==:choice
                    type_lines = Array{String}([string(i) for i in cfg.type.child.children])
                else
                    type_lines = Array{String}([string(cfg.type)])
                end
            end

            clock_len = length(clock_lines)
            type_len = length(type_lines)

            max_lines = max(clock_len,type_len)

            max_clock_width = 0
            max_type_width = 0

            # merge arrays into relative lines
            merged_lines = fill("",(max_lines,2))
            for y in 1:max_lines
                # check each line has element
                if y <= clock_len
                    merged_lines[y,1] = clock_lines[y]
                    if length(clock_lines[y]) > max_clock_width
                        max_clock_width = length(clock_lines[y])
                    end
                end
                if y <= type_len
                    merged_lines[y,2] = type_lines[y]
                    if length(type_lines[y]) > max_type_width
                        max_type_width = length(type_lines[y])
                    end
                end
            end

            field_sep = ", "
            max_clock_width += length(field_sep) - 1
            max_type_width += length(field_sep) - 1
            
            # return as each line of array
            if mode==:array
                return merged_lines
            elseif mode in [:local,:local_full]
                cfg_prefix = "( "
                cfg_suffix = " )"
                # create array of each line
                lines = Array{String}([])
                for y in 1:max_lines
                    pad_clock = string(merged_lines[y,1],repeat(" ", max_clock_width - length(merged_lines[y,1])))
                    pad_type = string(merged_lines[y,2],repeat(" ", max_type_width - length(merged_lines[y,2])))

                    push!(lines, string(
                        y==1 ? (max_lines==1 ? cfg_prefix : " / ") : (y==max_lines ? " \\ " : "|  "), 
                        pad_clock, 
                        y==1 ? string(field_sep, "{ ") : repeat(" ",4), 
                        pad_type, 
                        y==type_len ? string("} ") : repeat(" ",2),
                        y==1 ? (max_lines==1 ? cfg_suffix : " \\") : (y==max_lines ? " /" : "  |")
                    ))
                end
                return string(join(lines,string("\n")))
            end
        end
    end
    

    export Queue, head!

    mutable struct Queue
        children::Msgs

        Queue(tail::Msgs=Msgs()) = new(tail)
    end
    Base.show(q::Queue, io::Core.IO=stdout) = print(io,string(q))
    Base.string(q::Queue) = isempty(q) ? string("∅") : string(q.children)

    Base.isempty(q::Queue) = isempty(q.children)

    function head!(q::Queue)
        if length(q.children)>0
            _head=q.children[1]
            deleteat!(q.children,1)
            return _head
        else
            return nothing
        end
    end


    struct Social <: Configuration
        valuations::Valuations
        # type::T where {T<:SessionType}
        type::S
        queue::Queue
        
        Social(l::Local,queue::Queue=Queue()) = new(l.valuations,l.type,queue)
        Social(valuations::Valuations,type::Dual,queue::Queue=Queue()) = new(valuations,S(type.child),queue)
        
        function Social(valuations::Valuations,type::S,queue::Queue=Queue()) 
            if type.kind in [:choice,:interaction]
                # populate immediately relevant clocks
                if type.kind==:choice
                    _relevant_clocks = get_labels(Constraints([s.δ for s in type.child.children]))
                elseif type.kind==:interaction
                    _relevant_clocks = get_labels(Constraints([type.child.δ]))
                end

                for l in _relevant_clocks
                    Value!(valuations, l)
                end
            end
            new(valuations,type,queue)
        end
    end
    Base.show(c::Social, mode::Symbol, io::Core.IO = stdout) = print(io, string(c, mode))
    Base.show(c::Social, io::Core.IO = stdout) = print(io, string(c))
    function Base.string(cfg::Social, mode::Symbol=:default)
        if mode==:default
            return string("( ", join([string(cfg.valuations),string(cfg.type),string(cfg.queue)],", "), ")")
        else
            # arrays for each field
            clock_lines = Array{String}([string(cfg.valuations.system),[string(v) for v in cfg.valuations.clocks]...])

            if cfg.type.kind==:choice
                type_lines = Array{String}([string(i) for i in cfg.type.child.children])
            else
                type_lines = Array{String}([string(cfg.type)])
            end

            if length(cfg.queue.children)==0
                queue_lines = Array{String}(["∅"])
            else
                queue_lines = Array{String}([string(q) for q in cfg.queue.children])
            end

            clock_len = length(clock_lines)
            type_len = length(type_lines)
            queue_len = length(queue_lines)

            max_lines = max(clock_len,type_len,queue_len)

            max_clock_width = 0
            max_type_width = 0
            max_queue_width = 0

            # merge arrays into relative lines
            merged_lines = fill("",(max_lines,3))
            for y in 1:max_lines
                # check each line has element
                if y <= clock_len
                    merged_lines[y,1] = clock_lines[y]
                    if length(clock_lines[y]) > max_clock_width
                        max_clock_width = length(clock_lines[y])
                    end
                end
                if y <= type_len
                    merged_lines[y,2] = type_lines[y]
                    if length(type_lines[y]) > max_type_width
                        max_type_width = length(type_lines[y])
                    end
                end
                if y <= queue_len
                    merged_lines[y,3] = queue_lines[y]
                    if length(queue_lines[y]) > max_queue_width
                        max_queue_width = length(queue_lines[y])
                    end
                end
            end

            field_sep = ", "
            max_clock_width += length(field_sep) - 1
            max_type_width += length(field_sep) - 1
            max_queue_width += length(field_sep) - 1
            
            # return as each line of array
            cfg_prefix = "( "
            cfg_suffix = " )"
            # create array of each line
            lines = Array{String}([])
            for y in 1:max_lines
                pad_clock = string(merged_lines[y,1],repeat(" ", max_clock_width - length(merged_lines[y,1])))

                pad_type = string(merged_lines[y,2],repeat(" ", max_type_width - length(merged_lines[y,2])))

                pad_queue = string(merged_lines[y,3],repeat(" ", max_queue_width - length(merged_lines[y,3])))


                push!(lines, string(
                    y==1 ? (max_lines==1 ? cfg_prefix : " / ") : (y==max_lines ? " \\ " : "|  "), 
                    pad_clock, 
                    y==1 ? string(field_sep, "{ ") : repeat(" ",4), 
                    pad_type, 
                    y==type_len ? string("}", field_sep) : repeat(" ",3),
                    pad_queue,
                    y==1 ? (max_lines==1 ? cfg_suffix : " \\ ") : (y==max_lines ? " / " : "  |")
                ))
            end
            if mode==:array
                return lines
            elseif mode==:social
                return string(join(lines,string("\n")))
            end
        end
    end
    

    # from social to local configurations
    Base.convert(::Type{Local}, c::T) where {T<:Social} = Local(c.valuations,c.type)

    
    isend(c::Local) = (typeof(c.type) == End) ? true : false
    isend(c::Social) = (typeof(c.type) == End) ? true : false


    struct System <: Configuration
        lhs::Social
        rhs::Social

        # only one, make dual
        System(lhs::Local) = new(Social(lhs),Social(lhs.valuations,Dual(lhs.type)))
        System(lhs::Social) = new(lhs,Social(lhs.valuations,Dual(lhs.type),lhs.queue))

        System(lhs::Local,rhs::Local) = new(Social(lhs),Social(rhs))
        System(lhs::Social,rhs::Social) = new(lhs,rhs)
    end
    Base.show(c::System, mode::Symbol, io::Core.IO = stdout) = print(io, string(c,mode))
    Base.show(c::System, io::Core.IO = stdout) = print(io, string(c))
    function Base.string(c::System) 
        lhs = string(c.lhs,:array)
        rhs = string(c.rhs,:array)

        lhs_len = length(lhs)
        rhs_len = length(rhs)
        max_len = max(lhs_len,rhs_len)

        # create array of each line
        lines = Array{String}([])
        for y in 1:max_len
            current_line = []

            if y <= lhs_len
                push!(current_line,lhs[y])
            end

            # add parl
            push!(current_line, max_len==1 ? " | " : (max_len==2 ? " | " : (y in [1,max_len] ? "   " :  " | " )))

            if y <= rhs_len
                push!(current_line,rhs[y])
            end

            push!(lines,join(current_line))
        end
        return string(join(lines,string("\n")))
    end

    # construct system from array of 2 social
    function Base.convert(::Type{System}, t::T) where {T<:Array{Social}} 
        @assert length(t) == 2
        System(t[1],t[2])
    end

    Base.convert(::Type{System}, t::T) where {T<:Tuple{Social,Social}} = System(t[1],t[2])
    

    # get system as children
    Base.convert(::Type{Array{Social}}, t::System) = Array{Social}([t.lhs,t.rhs])


end