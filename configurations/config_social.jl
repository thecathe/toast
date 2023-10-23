module SocialConfigurations

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    
    using ..Configurations
    # using ..LocalConfigurations
    # using ..ConfigurationQueues

    export Social

    "Social Configurations are comprised of a Local Configuration, and a message queue."
    struct Social <: Configuration
        valuations::Valuations
        type::T where {T<:SessionType}
        queue::Queue
        # from local
        Social(l::Local,q::Queue=Queue()) = new(l.valuations,l.type,q)
        # 
        function Social(v::Valuations,t::T,q::Queue=Queue()) where {T<:SessionType}
            # init via local
            _ = Local(v,t)

            new(v,t,q)
        end
    end
    
    Base.show(c::Social, io::Core.IO = stdout) = print(io, string(c))
    Base.show(c::Social, mode::Symbol, io::Core.IO = stdout) = print(io, string(c, mode))
    Base.show(c::Social, modes::T, io::Core.IO = stdout) where {T<:Array{Symbol}}= print(io, string(c, modes...))

    function Base.string(c::Social, args...)
        # get mode
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        if mode==:default
            # :default - print inline
            return string("( ",string(c.valuations,mode),", ",string(c.type,mode),", ",string(c.queue,mode)," )")

        elseif mode in [:smart,:full]
            # :smart - show relevant clocks and type
            # :full - show all clocks and type
            # :expand - show all clocks and expanded type

            # check if second mode before final :arr/:str (default: arr)
            if length(args)>2 
                second_mode = args[2]
                format_mode = args[3]

            elseif length(args)>1 
                # get second arg and format mode if not all provided
                if args[2]==:expand
                    second_mode = args[2]
                    format_mode = :arr 
                else 
                    second_mode = :not_given
                    format_mode = args[2]
                end
            else
                # default format: str
                second_mode = :not_given
                format_mode = :str 
            end
            if second_mode==:expand
                @assert mode==:full "Social.string, cannot have :expand with :smart"
                arr_local = string(Local(c.valuations,c.type),:full,:expand,:social,:arr)
            else
                arr_local = string(Local(c.valuations,c.type),mode,:social,:arr)
            end
            
            arr_queue = Array{String}([string(c.queue,mode,:arr)...])

            # all should be same width
            local_width = Int(length(arr_local[1]))
            queue_width = Int(length(arr_queue[1]))

            # add extra to top and bottom
            insert!(arr_queue, 1, "")
            push!(arr_queue,"")

            height_local = length(arr_local)
            height_queue = length(arr_queue)
            config_height = max(height_local,height_queue)

            for y in 1:config_height
                # padd local and queue
                if y<=height_local
                    arr_local[y] = string(arr_local[y], repeat(" ", max(0,local_width-length(arr_local[y]))))
                else
                     push!(arr_local, repeat(" ", local_width))
                end
                if y<=height_queue
                    arr_queue[y] = string(arr_queue[y], repeat(" ", max(0,queue_width-length(arr_queue[y]))))
                else
                     push!(arr_queue, repeat(" ", queue_width))
                end
            end


            arr_build = Array{String}([])
            for y in 1:config_height
                # pad current child
                push!(arr_build, string(string(arr_local[y]), string(arr_queue[y])))
                # ^ vscode terminal will insert a space on the first line sometimes if it is too long
            end
            # how to return?
            if format_mode==:arr
                return arr_build

            elseif format_mode==:str
                config_height = length(arr_build)

                if config_height==1
                    str_start = "( "
                    str_end = " )"
                else
                    str_start = " / "
                    str_end = " / "
                end
                alt_top = string(repeat(" ", length(str_end)-3), " \\ ")
                alt_bot = string(" \\ ", repeat(" ", length(str_start)-3))
                lhs_buff = string("| ", repeat(" ", length(str_start)-2))
                rhs_buff = string(repeat(" ", length(str_end)-2), " |")

                arr_lines = Array{String}([])
                for y in 1:config_height
                    line = arr_build[y]
                    # add to array with necessary decorations
                    if y==1
                        if y==config_height
                            push!(arr_lines, string(str_start, line, str_end))
                        else
                            push!(arr_lines, string(str_start, line, alt_top))
                        end
                    elseif y==config_height
                        push!(arr_lines, string(alt_bot, line, str_end))
                    else
                        push!(arr_lines, string(lhs_buff, line, rhs_buff))
                    end
                end
                return string("\n",join(arr_lines, "\n"))
            else
                @error "Social.string, unexpected mode: $(string(args))"
            end

        else
            @error "Social.string, unexpected mode: $(string(args))"
        end
    end

end