module TypeChoice

    import Base.show
    import Base.string
    import Base.length
    import Base.isempty
    import Base.getindex
    import Base.iterate

    using ..SessionTypes
    using ..TypeInteract

    export Choice

    mutable struct Choice <: SessionType
        children::Array{Interact}
        Choice(children::T) where {T<:Array{Interact}} = new(children)
        # single interact
        Choice(child::T) where {T<:Interact} = Choice([child])
    end

    Base.show(s::Choice, io::Core.IO = stdout) = print(io, string(s))
    Base.show(s::Choice, mode::Symbol, io::Core.IO = stdout) = print(io, string(s,mode))

    function Base.string(s::Choice, mode::Symbol = :default) 
        if mode==:default
            # :default - string
            return string("{ ", join([string(c, :default) for c in s.children], ", "), " }")

        elseif mode==:tail
            # :tail - show if 'end' or 'α'
            return string("{§[$(length(s.children))]}")

        elseif mode==:stub
            # :stub - string without child
            # in this context, return widest stub of its children
            str_stubs = Array{String}([string(c, :stub) for c in s.children])
            curr_longest = -1
            longest_index = -1
            for c in 1:length(str_stubs)
                curr = str_stubs[c]
                if length(curr)>curr_longest
                    longest_index = c
                end
            end
            @assert longest_index!=-1 "TypeChoice.string (mode$(string(mode))), no longest_index found?\n$(string(str_stubs))"
            return str_stubs[longest_index]

        elseif mode==:expanded
            # :expanded - same as :full, with each tail expanded
            return string("{ ", join([string(c, :expanded) for c in s.children], ", "), " }")

        elseif mode==:full
            # :full - array of each line
            str_children = Array{String}([string(c, :default) for c in s.children])
            widest_child = maximum(length, str_children)
            num_children = length(str_children)

            if num_children==1
                str_start = "{ "
                str_end = " }"
            else
                str_start = "/ "
                str_end = " /"
            end
            alt_top = string(repeat(" ", length(str_end)-1), "\\")
            alt_bot = string("\\", repeat(" ", length(str_start)-1))
            lhs_buff = string("{", repeat(" ", length(str_start)-1))
            rhs_buff = string(repeat(" ", length(str_end)-1), "}")

            arr_build = Array{String}([])
            for y in 1:num_children
                # pad current child
                curr = str_children[y]
                padded = string(curr, repeat(" ", widest_child - length(curr)))
                # add to array with necessary decorations
                if y==1
                    push!(arr_build, string(str_start, padded, num_children==1 ? str_end : alt_top))
                elseif y==num_children
                    push!(arr_build, string(alt_bot, padded, str_end))
                else
                    push!(arr_build, string(lhs_buff, padded, rhs_buff))
                end
            end
            return arr_build

        elseif mode==:full_expanded
            # :full_expanded - array of each line, with each tail expanded=
            str_strut = " | "
            strut_len = length(str_strut)
            strut_used = false

            num_immediate_children = length(s.children)

            str_children = Array{String}([])
            for child_index in 1:num_immediate_children
                # fully expand each interaction
                arr_child_tail = string(s.children[child_index],:full_expanded)
                @assert arr_child_tail isa Array "TypeChoice.string (mode$(string(mode))), expected Array but got: $(string(typeof(arr_child_tail)))"
                
                arr_child_len = length(arr_child_tail)
                # if arr_child_len==1 curr contains choice (possibly in tail)
                for y in 1:arr_child_len
                    curr_child = arr_child_tail[y]
                    if y==1
                        # add current interact with child
                        push!(str_children, string(curr_child))
                    else
                        # add other child of tail, remove padding to accomodate for strut (if not last)
                        if child_index<num_immediate_children
                            push!(str_children, string(str_strut, curr_child[strut_len+1:end]))
                            strut_used = true
                        else
                            push!(str_children, string(curr_child))
                        end
                    end
                end

                # if strut used and not last and children not empty, add blank line
                if strut_used && child_index<num_immediate_children
                    push!(str_children, str_strut)
                    strut_used = false
                end
            end

            widest_child = maximum(length, str_children)
            num_children = length(str_children)

            if num_children==1
                str_start = "{ "
                str_end = " }"
            else
                str_start = "/ "
                str_end = " /"
            end
            alt_top = string(repeat(" ", length(str_end)-1), "\\")
            alt_bot = string("\\", repeat(" ", length(str_start)-1))
            lhs_buff = string("{", repeat(" ", length(str_start)-1))
            rhs_buff = string(repeat(" ", length(str_end)-1), "}")
            
            arr_build = Array{String}([])
            for y in 1:num_children # -1 to remove strut line spacing
                # pad current child
                curr = str_children[y]
                padded = string(curr, repeat(" ", widest_child - length(curr)))
                # add to array with necessary decorations
                if y==1
                    # println()
                    # println("choice z($(string(widest_child)) - $(string(length(curr))) = $(string(widest_child-length(curr)))): |$(repeat("z", widest_child - length(curr)))|")
                    # println("...|$(string(str_start, padded, num_children==1 ? str_end : alt_top))|")
                    push!(arr_build, string(str_start, padded, num_children==1 ? str_end : alt_top))
                elseif y==num_children
                    push!(arr_build, string(alt_bot, padded, str_end))
                else
                    push!(arr_build, string(lhs_buff, padded, rhs_buff))
                end
            end
            return arr_build

        elseif mode==:full_string
            # :full_string - stringify array of each line
            return string(join(string(s, :full), "\n"))

        elseif mode==:full_expanded_string
            # :full_string - stringify array of each line
            return string(join(string(s, :full_expanded), "\n"))

        else
            @error "TypeChoice.string, unexpected mode: $(string(mode))"
        end
    end

    Base.length(s::Choice) = length(s.children)
    Base.isempty(s::Choice) = isempty(s.children)
    Base.getindex(s::Choice, i::Int) = getindex(s.children, i)

    Base.iterate(s::Choice) = isempty(s) ? nothing : (s[1], Int(1))
    Base.iterate(s::Choice, i::Int) = (i >= length(s)) ? nothing : (s[i+1], i+1)

end