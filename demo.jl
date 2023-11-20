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
    export A, B, C, D

    function A(;mode::Symbol = :local, loop::Int = 0) 
        if mode==:local
            config = exa_local_config_b
        elseif mode==:social
            config = exa_social_config_b
        elseif mode==:system
            @error "Mode $(string(mode)) is not supported for this example."
        end

        show(config,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(config,:t,2))
        println()

        show(config,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(config,:send,Msg("a")))
        println()

        show(config,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(config,:t,2))
        println()
                
        show(config,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(config,:recv,Msg("b")))
        println()

        if mode==:social
            show(config,[:full,:expand,:str])
            println("\n\n")
            show(Transition!(config,:tau))
            println()
        end
        
        show(config,[:full,:expand,:str])
        println("\n\n")

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
        println("\n\n")
        show(Transition!(config,:send,Msg("a")))
        println()

        show(config,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(config,:t,2))
        println()
        
        show(config,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(config,:recv,Msg("b")))
        println()

        if mode==:social
            show(config,[:full,:expand,:str])
            println("\n\n")
            show(Transition!(config,:tau))
            println()
        end

        show(config,[:full,:expand,:str])
        println("\n\n")
    end
    
    function C(;mode::Symbol = :system, loop::Int = 3)
        if mode==:system
            config = System(Social(exa_local_config_c))

            show(config,[:full,:expand,:str])
            println("\n\n")
            show(Transition!(config,:tau,Msg("start")))
            println()

            show(config,[:full,:expand,:str])
            println("\n\n")
            show(Transition!(config,:tau))
            println()

            show(config,[:full,:expand,:str])
            println("\n\n")
            show(Transition!(config,:t,3))
            println()
                
            e_sent = false

            for _ in range(1,loop)

                if rand(1:3)<3
                    if e_sent
                        show(config,[:full,:expand,:str])
                        println("\n\n")
                        send_f = Transition!(config,:tau,Msg("f"))
                        show(send_f)
                        println()
                        if send_f.success
                            e_sent = false
                        end

                    else
                        show(config,[:full,:expand,:str])
                        println("\n\n")
                        send_e = Transition!(config,:tau,Msg("e"))
                        show(send_e)
                        println()
                        if send_e.success
                            e_sent = true
                        end

                    end

                else
                    show(config,[:full,:expand,:str])
                    println("\n\n")
                    show(Transition!(config,:tau))
                    println()

                end

            end
            
            show(config,[:full,:expand,:str])
            println("\n\n")

        else
            @error "Mode $(string(mode)) is not supported for this example."
        end
    end

    function runExample(;func::Function = B, loop::Int = 1)
        println("starting example...\n")
        func(;loop=loop)
        println("\nexample finished.")
    end


    function D(;loop::Int=1)
        if loop!=1
            @info "This example is only intended to be run once, so it will not be looped."
        end


        time_c_b = δ(:and, δ(:or, δ(:or, δ(:leq,"x",2), δ(:and, δ(:geq,"x",3), δ(:leq,"x",4))), δ(:geq,"x",5)), δ(:deq, "x", "y", 2))

        time_test = Social(
            ν([("x",2.5),("y",0.5)]),
            Interact(:recv, ("msg", Bool), time_c_b, λ()),
            Queue(Msgs([Msg("msg", Bool)]))
        ) 

        
        show(time_test,[:full,:expand,:str])
        println("\n\n")
        @info "The transition above failed as we cannot delay receiving the message."
        show(Transition!(time_test,:t,1))
        println()


        show(time_test,[:full,:expand,:str])
        println("\n\n")
        @info "The transition above failed as we cannot receive the message yet."
        show(Transition!(time_test,:tau))
        println()


        show(time_test,[:full,:expand,:str])
        println("\n\n")
        @info "The transition above succeeds as we have not had a chance to receive yet."
        show(Transition!(time_test,:t,0.1))
        println()


        show(time_test,[:full,:expand,:str])
        println("\n\n")
        @info "The transition above failed as we tried to \"jump\" over the viable region (3≤x≤4)."
        show(Transition!(time_test,:t,2))
        println()


        show(time_test,[:full,:expand,:str])
        println("\n\n")
        @info "The transition above succeeds, and we are now able to receive."

        show(Transition!(time_test,:t,0.4))
        println()

        show(time_test,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(time_test,:tau))
        println()

        show(time_test,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(time_test,:t,0.1))
        println()

        show(time_test,[:full,:expand,:str])
        println("\n\n")
        show(Transition!(time_test,:t,100))
        println()

        show(time_test,[:full,:expand,:str])
        println("\n\n")

    end


    # runExample(;func=C,loop=9)

    # D()



    function PresentationExamples()

        δ(:tt)

        δ(:gtr,"x",1)

        δ(:eq,"x",1)

        δ(:dgtr,"x","y",1)

        δ(:deq,"x","y",1)

        # δ(:not,δ(...))

        # δ(:and,δ(...),δ(...))

        Interact(:send,Msg("a",Bool),δ(:gtr,"x",2),λ("x"),End())

        Choice([
            Interact(:send,Msg("a",Bool),δ(:gtr,"x",2),λ("x"),End()),
            Interact(:recv,Msg("b",None),δ(:eq,"y",1),λ("y"),End())
        ])

    end

end