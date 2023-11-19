module Demo

    include("toast.jl")
    using .TOAST
    export Interact, Choice, End, μ, α
    export Local, Social, System
    export Transition!
    export Evaluate!
    export ν

    #
    # example types
    #
    export example_types
    example_types = Array{SessionType}([])

    exa_type_a = Interact(:send, ("a"), δ(:eq,"x",2), λ("x"),
        Interact(:recv, ("b"), δ(:eq,"x",2),λ("x"), End()))
    push!(example_types, exa_type_a)

    exa_type_b = μ("z", Interact(exa_type_a,α("z")))
    push!(example_types, exa_type_b)

    exa_type_c = Interact(:recv, ("start"), δ(), λ("x"),
        μ("z", Choice([
            Interact(:send, ("a"), δ(:eq,"x",2), λ("x"),
                Interact(:recv, ("b",String), δ(:eq,"x",2), λ(), End())),
            Interact(:send, ("c"), δ(:not,δ(:geq,"y",2)), λ("y"),
                Interact(:recv, ("d",String), δ(:geq,"x",2), λ(), End())),
            # Interact(:recv, ("e"), δ(:and,δ(:not,δ(:geq,"x",5)),δ(:geq,"x",3)), λ("y"),
            #     Interact(:send, ("f",String), δ(:eq,"y",2),λ(), End())),
            Interact(:recv, ("e"), δ(:geq,"x",2), λ("y"),
                Interact(:send, ("f",String), δ(:eq,"y",0), λ(), α("z")))
        ]))
    )
    push!(example_types, exa_type_c)

    exa_type_d = Interact(:recv, ("msg", Bool), δ(:and, 
                                                    δ(:or, 
                                                        δ(:or, 
                                                            δ(:leq,"x",2), 
                                                            δ(:and, 
                                                                δ(:geq,"x",3), 
                                                                δ(:leq,"x",4))
                                                        ), δ(:geq,"x",5)
                                                    ), δ(:deq, "x", "y", 2)), λ())

    push!(example_types, exa_type_d)

    #
    # example configurations
    #
    export example_local_configs
    example_local_configs = Array{Local}([])

    exa_local_config_a = Local(ν(), exa_type_a)
    push!(example_local_configs, exa_local_config_a)

    exa_local_config_b = Local(ν(), exa_type_b)
    push!(example_local_configs, exa_local_config_b)

    exa_local_config_c = Local(ν(), exa_type_c)
    push!(example_local_configs, exa_local_config_c)

    exa_local_config_d = Local(ν([("x",2.5),("y",0.5)]), exa_type_d)
    push!(example_local_configs, exa_local_config_d)

    exa_local_config_e = Local(ν([("x",2.5)]), exa_type_d)
    push!(example_local_configs, exa_local_config_e)


    export example_social_configs
    example_social_configs = Array{Social}([Social(c) for c in example_local_configs])

    export example_system_configs
    example_system_configs = Array{System}([System(c) for c in example_social_configs])


    #
    # make copies
    #
    copy_exa_local_config_a = deepcopy(exa_local_config_a)
    copy_exa_local_config_b = deepcopy(exa_local_config_b)
    copy_exa_local_config_c = deepcopy(exa_local_config_c)
    copy_exa_local_config_d = deepcopy(exa_local_config_d)
    copy_exa_local_config_e = deepcopy(exa_local_config_e)

    export reloadExamples
    function reloadExamples()
        exa_local_config_a = copy_exa_local_config_a
        exa_local_config_b = copy_exa_local_config_a
        exa_local_config_c = copy_exa_local_config_a
        exa_local_config_d = copy_exa_local_config_a
        exa_local_config_e = copy_exa_local_config_a

        example_local_configs = Array{Social}([
            exa_local_config_a,
            exa_local_config_b,
            exa_local_config_c,
            exa_local_config_d,
            exa_local_config_e
        ])
        
        example_social_configs = Array{Social}([Social(c) for c in example_local_configs])

        example_system_configs = Array{System}([System(c) for c in example_social_configs])

    end

    #
    # run
    #
    export runExample
    export A, B, C

    function A(;mode::Symbol = :local, loop::Int = 0) 
        if mode==:local
            config = exa_local_config_b
        elseif mode==:social
            config = exa_social_config_b
        elseif mode==:system
            @error "Mode $(string(mode)) is not supported for this example."
        end

        show(config,[:full,:expand,:str])
        println()
        show(Transition!(config,:t,2))
        println()

        show(config,[:full,:expand,:str])
        println()
        show(Transition!(config,:send,Msg("a")))
        println()

        show(config,[:full,:expand,:str])
        println()
        show(Transition!(config,:t,2))
        println()
                
        show(config,[:full,:expand,:str])
        println()
        show(Transition!(config,:recv,Msg("b")))
        println()

        if mode==:social
            show(config,[:full,:expand,:str])
            println()
            show(Transition!(config,:tau))
            println()
        end
        
        show(config,[:full,:expand,:str])
        println()

    end

    function B(;mode::Symbol = :local, loop::Int = 0) 
        if mode==:local
            config = exa_local_config_b
        elseif mode==:social
            config = exa_social_config_b
        elseif mode==:system
            @error "Mode $(string(mode)) is not supported for this example."
        end

        show(config,[:full,:expand,:str])
        println()
        show(Transition!(config,:send,Msg("a")))
        println()

        show(config,[:full,:expand,:str])
        println()
        show(Transition!(config,:t,2))
        println()
        
        show(config,[:full,:expand,:str])
        println()
        show(Transition!(config,:recv,Msg("b")))
        println()

        if mode==:social
            show(config,[:full,:expand,:str])
            println()
            show(Transition!(config,:tau))
            println()
        end

        show(config,[:full,:expand,:str])
        println()
    end
    
    function C(;mode::Symbol = :system, loop::Int = 3)
        if mode==:system
            config = System(Social(exa_local_config_c))

            show(config,[:full,:expand,:str])
            println()
            show(Transition!(config,:tau,Msg("start")))
            println()

            show(config,[:full,:expand,:str])
            println()
            show(Transition!(config,:tau))
            println()

            show(config,[:full,:expand,:str])
            println()
            show(Transition!(config,:t,3))
            println()
                
            e_sent = false

            for _ in range(1,loop)

                if rand(1:2)==1
                    if e_sent
                        show(config,[:full,:expand,:str])
                        println()
                        send_f = Transition!(config,:tau,Msg("f"))
                        show(send_f)
                        println()
                        if send_f.success
                            e_sent = false
                        end

                    else
                        show(config,[:full,:expand,:str])
                        println()
                        send_e = Transition!(config,:tau,Msg("e"))
                        show(send_e)
                        println()
                        if send_e.success
                            e_sent = true
                        end

                    end

                else
                    show(config,[:full,:expand,:str])
                    println()
                    show(Transition!(config,:tau))
                    println()

                end

            end
            
            show(config,[:full,:expand,:str])
            println()

        else
            @error "Mode $(string(mode)) is not supported for this example."
        end
    end

    function runExample(;func::Function = B, loop::Int = 1)
        println("starting example...\n")
        func(;loop=loop)
        println("\nexample finished.")
    end

end