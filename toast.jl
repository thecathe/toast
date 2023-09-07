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
    show_all_clock_tests=true
    show_clock_tests = true

    show_logical_clock_tests=false
    show_clock_constraints_tests=false

    #
    # type tests
    #
    show_all_type_tests=true
    show_type_tests=true

    show_interact_tests=false
    show_choice_tests=false
    show_rec_tests=false
    show_duality_tests=false

    #
    # configuration tests
    #
    show_all_configuration_tests=false
    show_configuration_tests=true

    show_configuration_tests=false  
    show_evaluate_tests=false  
    show_enabled_actions_tests=false

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

        u = Valuations(a)
        v = Valuations([a,b,c,d])

        # logical clocks
        if show_logical_clock_tests || show_all_clock_tests || show_all_tests
            println("logical clock tests:")

            show(a)
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

        h = μ("a", c)
        i = Interact(b,α("z"))
        j = μ("z",i)

        # interaction
        if show_interact_tests || show_all_type_tests || show_all_tests
            println("interact type tests:")

            fifo_tail = Interact([a,b,c,d,a,b])
            show(fifo_tail,:full)
            printlines()

            show(a,:full)
            printlines()

            show(b,:full)
            printlines()

            show(c,:full)
            printlines()

            show(d,:full)
            printlines()

            # anonymous interaction
            show(S(:recv, ("c", Int), δ(), λ("z")), :full)
            printlines()
        end

        # choice
        if show_choice_tests || show_all_type_tests || show_all_clock_tests
            println("choice type tests:")

            show(e,:full)
            printlines()
            
            show(f,:full)
            printlines()

            show(g,:full)
            printlines()

            # anonymous interaction
            show(S([a,b]), :full)
            printlines()
        end

        # recursion
        if show_rec_tests || show_all_type_tests || show_all_tests
            println("recursive type tests:")

            show(h,:full)
            printlines()

            show(i,:full)
            printlines()

            show(j,:full)
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
        

    end




    # #
    # # configurations and enabled actions
    # #
    # include("configurations.jl")
    # using .Configurations

    # include("evaluate.jl")
    # using .Evaluate

    # include("enabled_configuration_actions.jl")
    # using .EnabledConfigurationActions

    # if show_configuration_tests || show_all_configuration_tests || show_all_tests

    #     # configurations
    #     if show_configuration_tests || show_all_configuration_tests || show_all_tests 
    #         println("configuration tests:")

    #         _c = Clocks([("a",1)])
    #         _v = Valuations(_c)
    #         _s = S(Choice([(:send, Msg("a", Int), δ(:not,δ(:geq,"x",3)),[], Def("a", (:send, Msg("b", String), δ(:tt), [], Call("a")))),(:recv, Msg("c", Bool), δ(:geq,"y",3),[])]))
    #         _l = Local(_v,_s)

    #         show(_l)
    #         printlines()

    #         show(System(_l))
    #         printlines()


            
    #         _v = Valuations()
    #         s_b = S(([(:send, Msg("e", Data(Int)),δ(:eq,"x",1), []  ),(:send, Msg("f", Data(String)),δ(:eq,"x",2), []  ),(:recv, Msg("g", Data(Int)),δ(:eq,"x",4), []  ),(:send, Msg("h", Data(String)),δ(:eq,"x",5), []  )]))
    #         l_b1 = Local(_v,s_b)
    #         l_b2 = Local(_v,Dual(s_b))
    #         sys = System(l_b1,l_b2)


    #         # show(l_b1,:local)
    #         # printlines()

    #         # show(Social(l_b1),:social)
    #         # printlines()

    #         show(sys)
    #         printlines()

    #     end

    #     # evaluations
    #     if show_evaluate_tests || show_all_configuration_tests || show_all_tests
    #         println("evaluate tests:")

    #         clocks = Clocks([("a",1),("b",2),("c",3)])
    #         v = Valuations(clocks)

    #         # show(v)
    #         # printlines()

    #         a = δ(:eq, "x", 3)
    #         # b = δ(:not, a)
    #         # c = δ(:and, a, δ(:geq, "y", 4))
    #         b = δ(:not, δ(:eq, "a", 3))
    #         c = δ(:and, δ(:eq, "a", 1), δ(:geq, "c", 2))
    #         d = δ(:deq, "c", "y", 3)
    #         e = δ(:and, δ(:not, δ(:and, δ(:eq, "b", 1), δ(:geq, "x", 4))), δ(:and, δ(:eq, "a", 3), δ(:geq, "z", 4)))   


    #         show(v)
    #         println()
    #         show(Eval(v,a))
    #         printlines()

    #         show(v)
    #         println()
    #         show(Eval(v,b))
    #         printlines()
            
    #         show(v)
    #         println()
    #         show(Eval(v,c))
    #         printlines()
            
    #         show(v)
    #         println()
    #         show(Eval(v,d))
    #         printlines()
            
    #         show(v)
    #         println()
    #         show(Eval(v,e))
    #         printlines()

    #         show(v)
    #         println()
    #         show(Eval(v,a))
    #         printlines()

    #         show(v)
    #         println()
    #         show(Eval(v,b))
    #         printlines()
            
    #         show(v)
    #         println()
    #         show(Eval(v,c))
    #         printlines()
            
    #         show(v)
    #         println()
    #         show(Eval(v,d))
    #         printlines()
            
    #         show(v)
    #         println()
    #         show(Eval(v,e))
    #         printlines()


    #     end

    #     # enabled actions
    #     if show_enabled_actions_tests || show_all_configuration_tests || show_all_tests
    #         println("enabled actions tests:")

            
    #         _v = Valuations()
    #         s_b = S(([(:send, Msg("e", Data(Int)),δ(:eq,"x",1), []  ),(:send, Msg("f", Data(String)),δ(:eq,"x",2), []  ),(:recv, Msg("g", Data(Int)),δ(:eq,"x",4), []  ),(:send, Msg("h", Data(String)),δ(:eq,"x",5), []  )]))
    #         l_b1 = Local(_v,s_b)

    #         show(l_b1,:local)
    #         printlines()

    #         show(IsEnabled(l_b1))
    #         printlines()

    #         # for i ∈ range(1,5)

    #         #     show(TimeStep!(l_b1,1))
    #         #     printlines()

    #         #     show(IsEnabled(l_b1))
    #         #     printlines()

    #         # end

    #     end

    # end

    # #
    # # operational semantics of configurations
    # #
    # include("transition_labels.jl")
    # using .TransitionLabels

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

end