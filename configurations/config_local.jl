module LocalConfigurations

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes

    export Local

    struct Local
        valuations::Valuations
        type::T where {T<:SessionType}
        relevant_clocks::Array{String}

        function Local(val::Valuations,type::T) where {T<:SessionType}

            if type isa Choice || type isa Interact
                # populate immediately relevant clocks
                if type isa Interact
                    _t = Choice([type])
                else
                    _t = type
                end

                _relevant_clocks = Array{String}([])
                for i in _t.children
                    # get labels from flattened constraint of each interaction
                    push!(_relevant_clocks, [string(d) for d in δ(:flatten,i.constraints).clocks]...)
                    # add resets
                    push!(_relevant_clocks, [string(x) for x in i.resets]...)
                end

                # initialise values
                for l in _relevant_clocks
                    ValueOf!(val,l)
                end

                new(val,_t,_relevant_clocks)
            else
                # not choice or type
                new(val,type,[])
            end
        end

    end

    Base.show(c::Local, io::Core.IO = stdout) = print(io, string(c))
    Base.show(c::Local, mode::Symbol, io::Core.IO = stdout) = print(io, string(c, mode))
    Base.show(c::Local, modes::T, io::Core.IO = stdout) where {T<:Array{Symbol}}= print(io, string(c, modes...))

    function Base.string(c::Local, args...)
        # get mode
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        if mode==:default
            # show system clock and inline type
            return string("(", string(c.valuations,:system), ", ", string(c.type),")")

        elseif mode in [:smart,:full]
            # :smart - show relevant clocks and type
            # :full - show all clocks and type
            # :expand - show all clocks and expanded type
            
            # get clock, type array
            if mode==:smart
                arr_clocks = Array{String}([string(c.valuations,:smart,c.relevant_clocks)...])
                arr_type = Array{String}([string(c.type,:full,:arr)...])
                if length(args)>1 
                    if args[2]==:social
                        is_social=true
                        if length(args)>2
                            format_mode = args[3]
                        else
                            format_mode=:arr
                        end
                    else
                        format_mode = args[2]
                        is_social=false
                    end
                else
                    # defaults
                    format_mode = :str
                    second_mode = :not_given
                    is_social=false
                end
            else
                if length(args)>1 
                    if args[2]==:expand
                        second_mode=args[2]
                        if length(args)>2
                            if args[3]==:social
                                is_social=true
                                if length(args)>3
                                    format_mode=args[4]
                                else
                                    format_mode=:str
                                end
                            else
                                is_social=false
                                format_mode=args[3]
                            end
                        else
                            # defaults
                            format_mode = :str
                            second_mode = :not_given
                            is_social=false
                        end
                    else
                        second_mode = :not_given
                        if args[2]==:social
                            is_social=true
                            if length(args)>2
                                format_mode = args[3]
                            else
                                # defaults
                                format_mode = :str
                            end
                        else
                            format_mode = args[2]
                            is_social=false
                        end
                    end
                else
                    # defaults
                    format_mode = :str
                    second_mode = :not_given
                    is_social=false
                end
                
                arr_clocks = Array{String}([string(c.valuations,:full,:arr)...])
                if second_mode==:expand
                    @assert mode==:full "Local.string, cannot have :expand with :smart"
                    arr_type = Array{String}([string(c.type,:full_expanded,:arr)...])
                else
                    arr_type = Array{String}([string(c.type,:full,:arr)...])
                end
            end 

            # all should be same width 
            type_width = Int(length(arr_type[1]))
            clock_width = Int(length(arr_clocks[1]))

            # add top and buttom buffers to each
            insert!(arr_clocks, 1, "")
            insert!(arr_type, 1, "")
            push!(arr_clocks,"")
            push!(arr_type,"")

            height_clocks = length(arr_clocks)
            height_type = length(arr_type)
            config_height = max(height_clocks,height_type)

            for y in 1:config_height
                # padd clocks and types
                if y<=height_clocks
                    arr_clocks[y] = string(arr_clocks[y], repeat(" ", max(0,clock_width-length(arr_clocks[y]))))
                else
                     push!(arr_clocks, repeat(" ", clock_width))
                end
                if y<=height_type
                    arr_type[y] = string(arr_type[y], repeat(" ", max(0,type_width-length(arr_type[y]))))
                else
                     push!(arr_type, repeat(" ", type_width))
                end
            end

            # if height_type < config_height
            #     # pad arrays, type
            #     for _ in 1:config_height-height_type
            #         push!(arr_type, repeat(" ", type_width))
            #     end
            # elseif height_clocks < config_height
            #     # pad arrays, clock
            #     for _ in 1:config_height-height_clocks
            #         push!(arr_clocks, repeat(" ", clock_width))
            #     end
            # end

            field_sep = ", "
            blank_sep = repeat(" ", length(field_sep))
            # config_width = type_width+clock_width+length(blank_sep)

            arr_build = Array{String}([])
            for y in 1:config_height
                # if y==1||y==config_height
                #     # add padding at top and bottom
                #     push!(arr_build, string(repeat(" ",config_width)))
                # else
                # pad current child
                push!(arr_build, string(
                    string(arr_clocks[y]), 
                    string(y==height_clocks-1 ? field_sep : blank_sep), 
                    string(arr_type[y]), 
                    string(is_social ? (y==height_type-1 ? field_sep : blank_sep) : "")
                ))
                # ^ vscode terminal will insert a space on the first line sometimes if it is too long
                # end
            end

            # how to return?
            if format_mode==:arr
                return arr_build

            elseif format_mode==:str
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
                return string(join(arr_lines, "\n"))
            else
                @error "Local.string, unexpected mode: $(string(args))"
            end

        else
            @error "Local.string, unexpected mode: $(string(args))"
        end
    end

end