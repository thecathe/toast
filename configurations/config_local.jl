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

    function Base.string(c::Local, mode::Symbol=:default)
        if mode==:default
            # show system clock and inline type
            return string("(", string(c.valuations,:system), ", ", string(c.type),")")

        elseif mode in [:smart,:full,:full_expanded]
            # :smart - show relevant clocks and type
            # :full - show all clocks and type
            # :full_expanded - show all clocks and expanded type
            # get clock, type array
            if mode==:smart
                arr_clocks = string(c.valuations,:smart,c.relevant_clocks)
                arr_type = string(c.type,:full)
            else
                arr_clocks = string(c.valuations,:full)
                arr_type = string(c.type,mode)
            end 

            len_clocks = length(arr_clocks)
            len_type = length(arr_type)
            config_height = max(len_clocks,len_type)

            # all should be same width
            if len_type < config_height
                # pad arrays, type
                type_width = length(arr_type[1])
                for _ in 1:config_height-len_type
                    push!(arr_type, repeat(" ", type_width))
                end
            elseif len_clocks < config_height
                # pad arrays, clock
                clock_width = length(arr_clocks[1])
                for _ in 1:config_height-len_clocks
                    push!(arr_clocks, repeat(" ", clock_width))
                end
            end

            field_sep = ", "
            blank_sep = repeat(" ", length(field_sep))

            arr_build = Array{String}([])
            for y in 1:config_height
                # pad current child
                push!(arr_build, string(string(arr_clocks[y]), string(y==len_clocks ? field_sep : blank_sep), string(arr_type[y])))
                # ^ vscode terminal will insert a space on the first line sometimes if it is too long
            end
            return arr_build

        elseif mode in [:smart_string,:full_string,:full_expanded_string]
            # :full_string - stringify array of each line
            # :full_string - stringify array of each line

            if mode==:smart_string
                arr_lines = string(c, :smart)
            elseif mode==:full_string
                arr_lines = string(c, :full)
            elseif mode==:full_expanded_string
                arr_lines = string(c, :full_expanded)
            end
            config_height = length(arr_lines)

            if config_height==1
                str_start = "{ "
                str_end = " }"
            else
                str_start = " / "
                str_end = " / "
            end
            alt_top = string(repeat(" ", length(str_end)-3), " \\ ")
            alt_bot = string(" \\ ", repeat(" ", length(str_start)-3))
            lhs_buff = string("| ", repeat(" ", length(str_start)-2))
            rhs_buff = string(repeat(" ", length(str_end)-2), " |")

            arr_build = Array{String}([])
            for y in 1:config_height
                line = arr_lines[y]
                # add to array with necessary decorations
                if y==1
                    if y==config_height
                        push!(arr_build, string(str_start, line, str_end))
                    else
                        push!(arr_build, string(str_start, line, alt_top))
                    end
                elseif y==config_height
                    push!(arr_build, string(alt_bot, line, str_end))
                else
                    push!(arr_build, string(lhs_buff, line, rhs_buff))
                end
            end
            return string(join(arr_build, "\n"))

        else
            @error "Local.string, unexpected mode: $(string(mode))"
        end
    end

end