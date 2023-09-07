module LocalTransitionAct

    import Base.show
    import Base.string

    using ..General
    using ..LogicalClocks
    using ..SessionTypes
    using ..SessionTypeActions
    using ..ClockValuations
    using ..Configurations
    using ..Evaluate

    export Act!

    struct Act!
        success::Bool
        label::Label
        resets::Labels
        Act!(c::T,a::X) where {T<:Configuration,X<:Tuple{Symbol,Msg}} = Act!(c,Action(a...))
        # 
        function Act!(c::T,a::Action) where {T<:Configuration}
            # check type is an actiontype
            if c.type.child isa Choice
                # search for relevant action in choice
                for i in c.type.child
                    if i.direction==a.direction 
                        if i.msg.label==a.msg.label
                            # check if data or delegation
                            if a.msg.payload isa Data
                                if i.msg.payload isa Data
                                    # check if they are the exact same
                                    if a.msg.payload.child==i.msg.payload.child
                                        # check if constraints are met
                                        if Eval(c,i.constraints).result
                                            # reset clocks
                                            Reset!(c.valuations,i.resets)
                                            # proceeed to next type
                                            c.type.child=i.child
                                            return new(true,Label(string(a)),i.resets)
                                        else 
                                            return new(false,Label(string(a)),i.resets)
                                        end
                                    else
                                        @error "Act!, action has same label and payload type, but different datatypes:\n($(string(a.msg)))\n($(string(i.msg)))"
                                    end
                                else
                                    @error "Act!, action has same label but different payload type:\n($(string(a.msg)))\n($(string(i.msg)))"
                                end
                            elseif a.msg.payload isa Delegation
                                if i.msg.payload isa Delegation
                                    # unsure if contents need to be checked?
                                    @warn "Act!, action is delegation, and contents have not been checked:\n($(string(a.msg)))\n($(string(i.msg)))"
                                    
                                    # check if constraints are met
                                    if Eval(c,i.constraints).result
                                        # reset clocks
                                        Reset!(c.valuations,i.resets)
                                        # proceeed to next type
                                        c.type.child=i.child
                                        return new(true,Label(string(a)),i.resets)
                                    else 
                                        return new(false,Label(string(a)),i.resets)
                                    end
                                else
                                    @error "Act!, action has same label but different payload type:\n($(string(a.msg)))\n($(string(i.msg)))"
                                end
                            else 
                                @error "Act!, action ($(string(a))) has unknown payload type: $(string(typeof(a.msg.payload)))"
                            end
                        end
                    end
                end
                @error "Act!, action ($(string(a))) not found in choice: $(string(c.type.child))"
            elseif c.type.child isa Interaction
                if c.type.child.direction==a.direction 
                    if c.type.child.msg.label==a.msg.label
                        # check if data or delegation
                        if a.msg.payload isa Data
                            if c.type.child.msg.payload isa Data
                                # check if they are the exact same
                                if a.msg.payload.child==c.type.child.msg.payload.child
                                    # check if constraints are met
                                    if Eval(c,c.type.child.constraints).result
                                        # reset clocks
                                        Reset!(c.valuations,c.type.child.resets)
                                        # proceeed to next type
                                        c.type.child=c.type.child.child
                                        return new(true,Label(string(a)),c.type.child.resets)
                                    else 
                                        return new(false,Label(string(a)),c.type.child.resets)
                                    end
                                else
                                    @error "Act!, action has same label and payload type, but different datatypes:\n($(string(a.msg)))\n($(string(c.type.child.msg)))"
                                end
                            else
                                @error "Act!, action has same label but different payload type:\n($(string(a.msg)))\n($(string(c.type.child.msg)))"
                            end
                        elseif a.msg.payload isa Delegation
                            if c.type.child.msg.payload isa Delegation
                                # unsure if contents need to be checked?
                                @warn "Act!, action is delegation, and contents have not been checked:\n($(string(a.msg)))\n($(string(c.type.child.msg)))"
                                
                                # check if constraints are met
                                if Eval(c,c.type.child.constraints).result
                                    # reset clocks
                                    Reset!(c.valuations,c.type.child.resets)
                                    # proceeed to next type
                                    c.type.child=c.type.child.child
                                    return new(true,Label(string(a)),c.type.child.resets)
                                else 
                                    return new(false,Label(string(a)),c.type.child.resets)
                                end
                            else
                                @error "Act!, action has same label but different payload type:\n($(string(a.msg)))\n($(string(c.type.child.msg)))"
                            end
                        else 
                            @error "Act!, action ($(string(a))) has unknown payload type: $(string(typeof(a.msg.payload)))"
                        end
                    end
                end
            else
                @error "Act!, state not communication (type $(typeof(c.type.child))): $(string(c.type.child))"
            end
        end

    end
    Base.show(l::Act!,io::Core.IO=stdout) = print(io,string(l))
    function Base.string(l::Act!) 
        if l.success
            string("⟶ $(string(l.label)) [$(string(l.resets)) ↦ 0]")
        else
            string("̸⟶ $(string(l.label)) [$(string(l.resets)) ↦ 0]")
        end
    end

end