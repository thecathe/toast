module TOAST

    function printlines() 
        println()
        println()
    end

    show_all_tests=false
    show_tests=true

    #
    # clock tests
    #
    show_all_clock_tests=false
    show_clock_tests = true

    show_logical_clock_tests=false
    show_clock_constraints_tests=false

    #
    # type tests
    #
    show_all_type_tests=false
    show_type_tests=true

    show_interact_tests=false
    show_choice_tests=false
    show_rec_tests=false
    show_duality_tests=false
    show_fancy_print_tests=false

    #
    # configuration tests
    #
    show_all_configuration_tests=false
    show_configuration_tests=true

    show_local_configuration_tests=false  
    show_social_configuration_tests=false  
    show_system_configuration_tests=false  

    show_evaluate_tests=false  
    # show_enabled_actions_tests=false

    #
    # transition tests
    #
    show_all_transition_tests=false
    show_transition_tests=true

    show_all_local_transition_tests=false
    show_local_transition_tests=true
    show_local_tick_test=false
    show_local_unfold_test=false
    show_local_act_test=false

    show_all_social_transition_tests=true
    show_social_transition_tests=true
    show_social_que_test=false
    show_social_send_test=false
    show_social_recv_test=false
    show_social_time_test=false

    show_all_system_transition_tests=false
    show_system_transition_tests=true
    show_system_com_l_test=false
    show_system_com_r_test=false
    show_system_par_l_test=false
    show_system_par_r_test=false
    show_system_wait_test=false

    #
    # clocks and constraints
    #
    include("logical_clocks.jl")
    using .LogicalClocks

    if show_clock_tests || show_all_clock_tests || show_all_tests

        a = Clock("a", 1)
        b = Clock("b", 2)
        c = Clock("c", 3)
        d = Clock("d", 4)

        e = Valuations([("x",3),("y",4)])

        u = Valuations(a)
        v = Valuations([a,b,c,d])

        # logical clocks
        if show_logical_clock_tests || show_all_clock_tests || show_all_tests
            println("logical clock tests:")

            show(a)
            printlines()

            show(e)
            printlines()

            show(u)
            printlines()

            show(v)
            printlines()

            show(ValueOf!(v,"a"))
            printlines()
            
            show(ValueOf!(v,"z"))
            printlines()

            show(v)
            printlines()

            show(ResetClocks!(v,"c"))
            printlines()
            
            show(ValueOf!(v,"c"))
            printlines()

            show(v)
            printlines()

            show(TimeStep!(v,4))
            printlines()

            show(v)
            printlines()

        end

        a = δ(:eq, "x", 3)
        b = δ(:not, δ(:eq, "x", 3))
        c = δ(:and, δ(:eq, "x", 3), δ(:geq, "y", 4))
        d = δ(:deq, "x", "y", 3)
        e = δ(:and, δ(:not, δ(:and, δ(:eq, "w", 3), δ(:geq, "x", 4))), δ(:and, δ(:eq, "y", 3), δ(:geq, "z", 4))) 
        f = δ(:flatten,e)

        # clock constraints
        if show_clock_constraints_tests || show_all_clock_tests || show_all_tests
            println("clock constraints tests:")

            show(δ(:and, δ(:not, δ(:tt)), δ(:tt)))
            printlines()

            show(a)
            printlines()

            show(b)
            printlines()

            show(c)
            printlines()

            show(d)
            printlines()
  
            show(e)
            printlines()

            show(f)
            printlines()

        end

    end



    #
    # session types and actions
    #
    include("session_types.jl")
    using .SessionTypes
    
    if show_type_tests || show_all_type_tests || show_all_tests

        a = Interact(Direction(:send), Msg("a"), δ(), λ(), End())
        b = Interact(:recv, ("b", Bool), δ(), λ())
        c = Interact(a,b)
        d = Interact(b,a)

        e = Choice(a)
        f = Choice([a,b])
        g = Choice([a,b,c,d])

        h = μ("a",c)
        i = Interact(b,α("z"))
        j = μ("z",i)

        k = μ("z",Choice([Interact(d,g),Interact(a,e),Interact([b,a,μ("x",Choice([Interact(c,α("x")),i]))])]))
        l = Interact(b,k)
        m = Choice([Interact([a,c,d,g]),l])
        n = μ("y",Choice([Interact([d,g]),l,Interact(b,Choice([Interact(a,k),a]))]))

        # interaction
        if show_interact_tests || show_all_type_tests || show_all_tests
            println("interact type tests:")

            fifo_tail = Interact([a,b,c,d,a,b])
            show(fifo_tail,:full_expanded_string)
            printlines()

            show(a,:full_expanded_string)
            printlines()

            show(b,:full_expanded_string)
            printlines()

            show(c,:full_expanded_string)
            printlines()

            show(d,:full_expanded_string)
            printlines()

            # anonymous interaction
            show(S(:recv, ("c", Int), δ(), λ("z")), :full_expanded_string)
            printlines()
        end

        # choice
        if show_choice_tests || show_all_type_tests || show_all_clock_tests
            println("choice type tests:")

            show(e,:full_expanded_string)
            printlines()
            
            show(f,:full_expanded_string)
            printlines()

            show(g,:full_expanded_string)
            printlines()

            # anonymous interaction
            show(S([a,b]), :full_expanded_string)
            printlines()
        end

        # recursion
        if show_rec_tests || show_all_type_tests || show_all_tests
            println("recursive type tests:")

            show(h,:full_expanded_string)
            printlines()

            show(i,:full_expanded_string)
            printlines()

            show(j,:full_expanded_string)
            printlines()

        end
        
        # duality
        if show_duality_tests || show_all_type_tests || show_all_tests
            println("duality type tests:")

            show(Duality(c),:full)
            printlines()

            show(Duality(e),:full)
            printlines()

            show(Duality(g),:full)
            printlines()

            show(Duality(j),:full)
            printlines()

        end

        # fancy prints
        if show_fancy_print_tests || show_all_type_tests || show_all_tests
            println("fancy type tests:")

            printlines()
            println("k:")
            show(k,:full_string)
            printlines()
            printlines()
            
            printlines()
            println("l:")
            show(l,:full_string)
            printlines()
            printlines()
            
            printlines()
            println("m:")
            
            show(m,:full_string)
            printlines()
            printlines()
            
            printlines()
            println("n:")
            show(n,:full_string)
            printlines()
            printlines()
            
            println("fancy type tests (expanded):")
            printlines()
            println("k:")
            show(k,:full_expanded_string)
            printlines()
            printlines()
            
            printlines()
            println("l:")
            show(l,:full_expanded_string)
            printlines()
            printlines()
            
            printlines()
            println("m:")
            
            show(m,:full_expanded_string)
            printlines()
            printlines()
            
            printlines()
            println("n:")
            show(n,:full_expanded_string)
            printlines()
            printlines()
        end
        

    end




    #
    # configurations and enabled actions
    #
    include("configurations.jl")
    using .Configurations

    # include("evaluate.jl")
    # using .Evaluate

    # include("enabled_configuration_actions.jl")
    # using .EnabledConfigurationActions

    if show_configuration_tests || show_all_configuration_tests || show_all_tests

        
        a = Interact(Direction(:send), Msg("a"), δ(), λ(), End())
        b = Interact(:recv, ("b", Bool), δ(:geq, "x", 3), λ())
        c = Interact(a,b)
        d = Interact(b,a)

        e = Choice([
            Interact(:send, Msg("a"), δ(:eq, "x", 2), λ("y"), 
                μ("p", 
                    Choice([
                        Interact(:recv, Msg("b"), δ(:not, δ(:geq, "y", 1)), λ()),
                        Interact(:send, Msg("c"), δ(:eq, "y", 1), λ("y"), α("p")),
                        Interact(:send, Msg("d"), δ(:geq, "x", 4), λ())
                    ])
                )
            ),
            # Interact(:send, Msg("e"), δ(:eq, "y", 1), λ()),
            Interact(:send, Msg("e"), δ(:and, δ(:geq, "y", 2), δ(:not, δ(:geq, "y", 3))), λ()),
            # Interact(:recv, Msg("f"), δ(:eq, "z", 3), λ(["x","y"]),
            Interact(:recv, Msg("f"), δ(:not, δ(:geq, "z", 1)), λ(["x","y"]),
                Choice([
                    Interact(:recv, Msg("g"), δ(:not, δ(:geq, "y", 1)), λ(),
                        Choice([
                                Interact(:recv, Msg("h"), δ(:not, δ(:geq, "y", 1)), λ()),
                                Interact(:send, Msg("i"), δ(:geq, "x", 4), λ())
                        ])
                    ),
                    Interact(:send, Msg("j"), δ(:geq, "x", 4), λ(["l","m","a","o"]))
                ])
            ),
            Interact(:send, Msg("k"), δ(:geq, "x", 5), λ()),
            Interact(:recv, Msg("zero"), δ(:eq, "w", 3), λ("y"))
        ])

        v_a = Valuations([("w",3)],0)
        v_b = Valuations()

        local_a = Local(v_a, e)
        social_a = Social(v_a, e)

        # sys = System(a,b)

        # configurations
        if show_local_configuration_tests || show_all_configuration_tests || show_all_tests 
            println("local configuration tests:")

            show(local_a,[:default])
            printlines()
            
            show(local_a,[:smart,:str])
            printlines()
            
            show(local_a,[:full,:str])
            printlines()
            
            show(local_a,[:full,:expand,:str])
            printlines()
        end

        # show_social_configuration_tests = true
        if show_social_configuration_tests || show_all_configuration_tests || show_all_tests 
            println("social configuration tests:")

            show(social_a,[:default])
            printlines()
            
            show(social_a,[:smart,:str])
            printlines()
            
            show(social_a,[:full,:str])
            printlines()
            
            show(social_a,[:full,:expand,:str])
            printlines()
        end

        if show_system_configuration_tests || show_all_configuration_tests || show_all_tests 
            println("system configuration tests:")

            show(sys)
            printlines()

        end
        
        # evaluations
        if show_evaluate_tests || show_all_configuration_tests || show_all_tests
            println("evaluate tests:")

            show(Evaluate!(social_a),[:full,:expand,:str])
            printlines()

            show(TimeStep!(v_a,1))
            printlines()

            show(Evaluate!(social_a),[:full,:expand,:str])
            printlines()

            show(TimeStep!(v_a,1))
            printlines()

            show(Evaluate!(social_a),[:full,:expand,:str])
            printlines()

            show(TimeStep!(v_a,1))
            printlines()

            show(Evaluate!(social_a),[:full,:expand,:str])
            printlines()

            show(TimeStep!(v_a,1))
            printlines()

            show(Evaluate!(social_a),[:full,:expand,:str])
            printlines()

            show(TimeStep!(v_a,1))
            printlines()

            show(Evaluate!(social_a),[:full,:expand,:str])
            printlines()

            show(TimeStep!(v_a,1))
            printlines()

            show(Evaluate!(social_a),[:full,:expand,:str])
            printlines()


        end

        #
        # operational semantics of configurations
        #
        include("transitions.jl")
        using .Transitions

        println("operational semantic tests:")

        test_a = deepcopy(local_a)
        test_b = deepcopy(local_a)
        test_c = deepcopy(local_a)

        # println("\ntest a:")
        # show(test_a,[:full,:expand,:str])
        # printlines()

        # show(Transition!(test_a,:recv,Msg("zero")))
        # printlines()

        # show(test_a,[:full,:expand,:str])
        # printlines()



        println("\ntest b:")
        show(test_b,[:full,:expand,:str])
        printlines()

        show(Transition!(test_b,:send,Msg("a")))
        printlines()

        show(test_b,[:full,:expand,:str])
        printlines()

        show(Transition!(test_b,:t,2))
        printlines()

        show(test_b,[:full,:expand,:str])
        printlines()

        show(Transition!(test_b,:send,Msg("a")))
        printlines()

        show(test_b,[:full,:expand,:str])
        printlines()



        
        # println("\ntest c:")
        # show(test_c,[:full,:expand,:str])
        # printlines()

        # show(Transition!(local_a,:recv,Msg("zero")))
        # printlines()

        # show(test_c,[:full,:expand,:str])
        # printlines()






        # show(Tick!(social_a,1))
        # printlines()

        # show(social_a,[:full,:expand,:str])
        # printlines()

        # show(Tick!(social_a,1))
        # printlines()

        # show(social_a,[:full,:expand,:str])
        # printlines()

        
    end






    # # local transitions
    # include("transitions_local/transition_tick.jl")
    # using .LocalTransitionTick

    # include("transitions_local/transition_unfold.jl")
    # using .LocalTransitionUnfold
    
    # include("transitions_local/transition_act.jl")
    # using .LocalTransitionAct

    
    # # social transitions
    # include("transitions_social/transition_que.jl")
    # using .SocialTransitionQue

    # include("transitions_social/transition_send.jl")
    # using .SocialTransitionSend
 
    # include("transitions_social/transition_recv.jl")
    # using .SocialTransitionRecv
 
    # include("transitions_social/transition_time.jl")
    # using .SocialTransitionTime


    # # system transitions
    # include("transitions_system/transition_com_l.jl")
    # using .SystemTransitionComL
    
    # include("transitions_system/transition_com_r.jl")
    # using .SystemTransitionComR
    
    # include("transitions_system/transition_par_l.jl")
    # using .SystemTransitionParL
    
    # include("transitions_system/transition_par_r.jl")
    # using .SystemTransitionParR
    
    # include("transitions_system/transition_wait.jl")
    # using .SystemTransitionWait
 
    # if show_transition_tests || show_all_transition_tests || show_all_tests

    #     # local transitions
    #     if show_local_transition_tests || show_all_local_transition_tests || show_all_tests

    #         # tick
    #         if show_local_tick_test || show_all_local_transition_tests ||show_all_tests
    #             println("local transition tick tests:")

    #             _v = Valuations()
    #             s_b = S(([(:send, Msg("e", Data(Int)),δ(:eq,"x",1), []  ),(:send, Msg("f", Data(String)),δ(:eq,"x",2), []  ),(:recv, Msg("g", Data(Int)),δ(:eq,"x",4), []  ),(:send, Msg("h", Data(String)),δ(:eq,"x",5), []  )]))
    #             l_b1 = Local(_v,s_b)

    #             show(l_b1,:local)
    #             printlines()

    #             show(IsEnabled(l_b1))
    #             printlines()

    #             for i ∈ range(1,5)

    #                 show(TimeStep!(l_b1,1))
    #                 printlines()

    #                 show(IsEnabled(l_b1))
    #                 printlines()

    #             end
    #         end

    #         # unfold
    #         if show_local_unfold_test || show_all_local_transition_tests ||show_all_tests
    #             println("local transition unfold tests:")

    #             _v = Valuations()
    #             s_b = S(Def("a", (:send, Msg("a", Data(Int)), δ(:tt), [], ([
    #                 (:send, Msg("e", Data(Int)),δ(:eq,"x",1), []  ),
    #                 (:send, Msg("f", Data(String)),δ(:eq,"x",2), [], Call("a")  ),
    #                 (:recv, Msg("g", Data(Int)),δ(:eq,"x",4), []  ),
    #                 (:send, Msg("h", Data(String)),δ(:eq,"x",5), [], Call("a")  )]))))
    #             l_b1 = Local(_v,s_b)

    #             show(l_b1,:local_full)
    #             printlines()

    #             Unfold!(l_b1)

    #             show(l_b1,:local_full)
    #             printlines()

    #         end

    #         # act
    #         if show_local_act_test || show_all_local_transition_tests ||show_all_tests
    #             println("local transition act tests:")

    #             _v = Valuations()
    #             s_b = S(([(:send, Msg("e", Data(Int)),δ(:eq,"x",1), Labels(["x"])  ),(:send, Msg("f", Data(String)),δ(:eq,"x",2), Labels([])  ),(:recv, Msg("g", Data(Int)),δ(:eq,"x",4),Labels([])  ),(:send, Msg("h", Data(String)),δ(:eq,"x",5), Labels([])  )]))
    #             l_b1 = Local(_v,s_b)

    #             show(TimeStep!(l_b1,0))
    #             printlines()

    #             show(l_b1,:local_full)
    #             printlines()

    #             show(Act!(l_b1,(:send, Msg("e",Data(Int)))))
    #             printlines()

    #             show(l_b1,:local_full)
    #             printlines()

    #             show(TimeStep!(l_b1,1))
    #             printlines()

    #             show(l_b1,:local_full)
    #             printlines()

    #             show(Act!(l_b1,(:send, Msg("e",Data(Int)))))
    #             printlines()

    #             show(l_b1,:local_full)
    #             printlines()
    #         end

    #     end

    #     # social transitions
    #     if show_social_transition_tests || show_all_social_transition_tests || show_all_tests

    #         # que
    #         if show_social_que_test || show_all_social_transition_tests || show_all_tests
    #             println("social transition que tests:")

    #             _v = Valuations()
    #             s_b = S(([(:send, Msg("e", Data(Int)),δ(:eq,"x",1), Labels(["x"])  ),(:send, Msg("f", Data(String)),δ(:eq,"x",2), Labels([])  ),(:recv, Msg("g", Data(Int)),δ(:eq,"x",4),Labels([])  ),(:send, Msg("h", Data(String)),δ(:eq,"x",5), Labels([])  )]))
    #             l_b1 = Local(_v,s_b)

    #             show(l_b1)

    #         end

    #         # send
    #         if show_social_send_test || show_all_social_transition_tests || show_all_tests
    #             println("social transition send tests:")

    #         end

    #         # recv
    #         if show_social_recv_test || show_all_social_transition_tests || show_all_tests
    #             println("social transition recv tests:")

    #         end

    #         # time
    #         if show_social_time_test || show_all_social_transition_tests || show_all_tests
    #             println("social transition time tests:")

    #         end

    #     end

    #     # system transitions
    #     if show_system_transition_tests || show_all_system_transition_tests || show_all_tests

    #         # com-l
    #         if show_system_com_l_test || show_all_system_transition_tests || show_all_tests
    #             println("system transition com-l tests:")

    #         end
            
    #         # com-r
    #         if show_system_com_r_test || show_all_system_transition_tests || show_all_tests
    #             println("system transition com-r tests:")

    #         end
            
    #         # par-l
    #         if show_system_par_l_test || show_all_system_transition_tests || show_all_tests
    #             println("system transition par-l tests:")

    #         end
            
    #         # par-r
    #         if show_system_par_r_test || show_all_system_transition_tests || show_all_tests
    #             println("system transition par-r tests:")

    #         end
            
    #         # wait
    #         if show_system_wait_test || show_all_system_transition_tests || show_all_tests
    #             println("system transition wait tests:")

    #         end
    #     end

    # end

    # ~ 
    # ~ user demos
    # ~
    # export Num, Clock, λ, Valuations, ValueOf!, ResetClocks!, TimeStep!, δ, δExpr, supported_constraints

    # export End
    # export μ
    # export α
    # export Direction, type_direction
    # export Msg, Payload, None, SpecialPayload
    # export Interact
    # export Choice
    # export Action
    # export Actions
    # export Msgs
    # export Del
    # export Duality, dual
    # export S

    # export Configuration, Local, Social, System
    # export Queue, head!
    # export Eval, δEval
    # export IsEnabled

    # export Tick!


end