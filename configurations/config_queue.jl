module ConfigurationQueues

    import Base.show
    import Base.string

    import Base.length
    import Base.isempty

    import Base.push!

    import Base.deleteat!
    import Base.getindex
    import Base.iterate

    using ...SessionTypes
    # import ...SessionTypes.TypeMsgs

    export Queue, head!

    mutable struct Queue
        children::Msgs
        Queue() = Queue(Msgs())
        Queue(tail::Msgs) = new(tail)
    end

    Base.show(q::Queue, io::Core.IO=stdout) = print(io,string(q))
    Base.show(q::Queue, mode::Symbol, io::Core.IO=stdout) = print(io,string(q, mode))

    function Base.string(q::Queue, args...)
        # get mode
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        if isempty(q)# how to return? (default: arr)
            if length(args)>1
                second_mode = args[2]
            else
                second_mode = :arr
            end
            if second_mode==:str
                return "∅" 
            elseif second_mode==:arr
                return Array{String}(["∅"])
            else
                @error "Queue.string, unexpected second mode: $(string(second_mode))"
            end
        else

            if mode==:default
                # :default - print all inline
                return string(join(q.children, "; "))

            elseif mode==:full
                # :full - print full queue as array
                arr_msgs = Array{String}([])
                for m in q.children
                    push!(arr_msgs, string(m))
                end

                widest_msg = maximum(length, arr_msgs)
                num_msgs = length(arr_msgs)

                arr_build = Array{String}([])
                for y in 1:num_msgs
                    curr = arr_msgs[y]
                    push!(arr_build, string(curr, repeat(" ", widest_msg-length(curr))))
                end

                # how to return? (default: arr)
                if length(args)>1
                    second_mode = args[2]
                else
                    second_mode = :arr
                end
                if second_mode==:str
                    return string(join(arr_build, "\n"))
                elseif second_mode==:arr
                    return arr_build
                else
                    @error "Queue.string, unexpected second mode: $(string(second_mode))"
                end

            elseif mode==:smart
                # :smart - print head of queue and hide tail
                queue_length = length(q)
                head = q[1]
                tail = queue_length>2 ? "; 𝙼[$(queue_length-1)]" : "; ∅"
                str_queue = string(string(head),string(tail))
                
                # how to return? (default: arr)
                if length(args)>1
                    second_mode = args[2]
                else
                    second_mode = :arr
                end
                if second_mode==:str
                    return str_queue
                elseif second_mode==:arr
                    return Array{String}([str_queue])
                else
                    @error "Queue.string, unexpected second mode: $(string(second_mode))"
                end

            else
                @error "Queue.string, unexpected mode: $(string(args))"
            end
        end
    end

    Base.length(q::Queue) = length(q.children)
    Base.isempty(q::Queue) = isempty(q.children)

    Base.getindex(q::Queue, i::Int) = getindex(q.children,i)
    Base.deleteat!(q::Queue, i::Int) = deleteat!(q.children,i)

    Base.iterate(q::Queue) = isempty(q) ? nothing : (q[1], Int(1))
    Base.iterate(q::Queue, i::Int) = i>=length(q) ? nothing : (q[i+1], i+1)

    Base.push!(q::Queue,m::Msg) = push!(q.children,m)

    # return head (default: delete from queue)
    function head!(q::Queue; pop::Bool=true)::Tuple{Union{Msg,Nothing},Bool} 
        if isempty(q) 
            @debug "head! called on empty Queue."
            return (Nothing(),false)
        end

        head=q[1]
        if pop
            deleteat!(q.children,1)
        end
        return (head,true)
    end

end