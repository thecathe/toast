module SystemConfigurations

    import Base.show
    import Base.string

    using ...LogicalClocks
    using ...SessionTypes
    
    using ..Configurations

    export System

    "System Configurations are comprised of two Social Configurations running in parallel."
    mutable struct System <: Configuration
        lhs::Social
        rhs::Social

        # construct from one type (using dual of other)
        System(lhs::Local) = System(Social(lhs))
        System(lhs::Social) = System(lhs,Social(lhs.valuations,Duality(lhs.type).dual,Queue()))

        System(lhs::Social,rhs::Social) = new(lhs,rhs)

    end

    Base.show(c::System, io::Core.IO = stdout) = print(io, string(c))
    Base.show(c::System, mode::Symbol, io::Core.IO = stdout) = print(io, string(c, mode))
    Base.show(c::System, modes::T, io::Core.IO = stdout) where {T<:Array{Symbol}}= print(io, string(c, modes...))


    function Base.string(c::System, args...)
        # get mode
        if length(args)==0
            mode=:default
        else
            mode=args[1]
        end

        lhs = c.lhs
        rhs = c.rhs

        if mode==:default
            # :default - print inline
            return string("$(string(lhs,:default)) | $(string(rhs,:default))")

        elseif mode in [:smart,:full]
            # :smart - show relevant clocks and type
            # :full - show all clocks and type
            # :expand - show all clocks and expanded type

            temp_args = replace(args, :str=>:arr)

            lhs_arr = string(lhs,temp_args...,:brackets)
            rhs_arr = string(rhs,temp_args...,:brackets)

            lhs_max = length(lhs_arr)
            rhs_max = length(rhs_arr)

            lhs_width = length(lhs_arr[1])
            rhs_width = length(rhs_arr[1])

            lhs_buffer = string(repeat(" ",lhs_width))
            rhs_buffer = string(repeat(" ",rhs_width))

            # @info "System.string, $(string(max(lhs_max,rhs_max))) = max($(lhs_max),$(rhs_max))."

            # merge into one
            arr_lines = Array{String}([])
            for i in range(1,max(lhs_max,rhs_max))
                curr_line = ""
                # lhs
                if i <= lhs_max
                    curr_line = "$(curr_line)$(lhs_arr[i])"
                else
                    curr_line = "$(curr_line)$(lhs_buffer)"
                end

                curr_line = "$(curr_line) | "

                # rhs
                if i <= rhs_max
                    curr_line = "$(curr_line)$(rhs_arr[i])"
                else
                    curr_line = "$(curr_line)$(rhs_buffer)"
                end
                push!(arr_lines,curr_line)
            end

            if :arr ∈ args
                @assert :str ∉ args "System.string, cannot have both :arr and :str as arguments."
                return arr_lines
            else
                return string(join(arr_lines,"\n"))
            end
            # # check if second mode before final :arr/:str (default: arr)
            # if length(args)>2 
            #     second_mode = args[2]
            #     format_mode = args[3]

            # elseif length(args)>1 
            #     # get second arg and format mode if not all provided
            #     if args[2]==:expand
            #         second_mode = args[2]
            #         format_mode = :arr 
            #     else 
            #         second_mode = :not_given
            #         format_mode = args[2]
            #     end
            # else
            #     # default format: str
            #     second_mode = :not_given
            #     format_mode = :str 
            # end

            # if second_mode==:expand
            #     @assert mode==:full "System.string, cannot have :expand with :smart"
            #     lhsarr_local = string(Local(c.valuations,c.type),:full,:expand,:social,:arr)
            # else
            #     arr_local = string(Local(c.valuations,c.type),mode,:social,:arr)
            # end
            
            # arr_queue = Array{String}([string(c.queue,mode,:arr)...])

        end
    end

end