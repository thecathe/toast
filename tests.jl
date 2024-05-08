### A Pluto.jl notebook ###
# v0.19.41

## show or hide debug?
ENV["JULIA_DEBUG"] = "all"


using Markdown
using InteractiveUtils

using Test

include("toast.jl")
using .TOAST


@info "beginning tests..."

# clock valuation tests
begin
    # init with a=2
    clock_valuations_a_2 = ν([("a",2)])
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==2
    @test ValueOf!(clock_valuations_a_2, "b").value==0

    # reset a->0
    ResetClocks!(clock_valuations_a_2,"a")
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==0
    @test ValueOf!(clock_valuations_a_2, "b").value==0

    # time step 1
    TimeStep!(clock_valuations_a_2,1)
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==1
    @test ValueOf!(clock_valuations_a_2, "b").value==1
    @test ValueOf!(clock_valuations_a_2, "c").value==1

    # reset a->0
    ResetClocks!(clock_valuations_a_2,"a")
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==0
    @test ValueOf!(clock_valuations_a_2, "b").value==1
    @test ValueOf!(clock_valuations_a_2, "c").value==1

    # time step 2
    TimeStep!(clock_valuations_a_2,2)
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==2
    @test ValueOf!(clock_valuations_a_2, "b").value==3
    @test ValueOf!(clock_valuations_a_2, "c").value==3
    @test ValueOf!(clock_valuations_a_2, "d").value==3
        
    # reset {a,c}->0
    ResetClocks!(clock_valuations_a_2,["a","c"])
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==0
    @test ValueOf!(clock_valuations_a_2, "b").value==3
    @test ValueOf!(clock_valuations_a_2, "c").value==0
    @test ValueOf!(clock_valuations_a_2, "d").value==3

    # time step 3
    TimeStep!(clock_valuations_a_2,3)
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==3
    @test ValueOf!(clock_valuations_a_2, "b").value==6
    @test ValueOf!(clock_valuations_a_2, "c").value==3
    @test ValueOf!(clock_valuations_a_2, "d").value==6
        
    # reset all
    ResetClocks!(clock_valuations_a_2)
    @debug string(clock_valuations_a_2)
    @test ValueOf!(clock_valuations_a_2, "a").value==0
    @test ValueOf!(clock_valuations_a_2, "b").value==0
    @test ValueOf!(clock_valuations_a_2, "c").value==0
    @test ValueOf!(clock_valuations_a_2, "d").value==0
    @test ValueOf!(clock_valuations_a_2, "e").value==6


    @info "all clock valuation tests passed."
end


# constraint evaluation tests
begin
    function debug_test(clock_valuations,clock_constraints,expected)
        evaluation = eval(δEvaluation!(clock_valuations,clock_constraints).expr)
        @debug string("($(string(clock_valuations)) ⊧ $(string(clock_constraints))) == $(string(evaluation))")
        @test evaluation==expected
    end

    # equality constraints
    begin
        clock_constraints = δ(:eq, "x", 3)
        # simple tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2)])
            @debug string("evaluating $(string(clock_constraints))")

            # base test
            debug_test(clock_valuations,clock_constraints,false)

            # time step 2
            TimeStep!(clock_valuations,2)
            debug_test(clock_valuations,clock_constraints,false)

            # reset
            ResetClocks!(clock_valuations)
            debug_test(clock_valuations,clock_constraints,false)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,clock_constraints,true)

            # time step 1
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,clock_constraints,false)

            @info "simple equality constraint tests passed."
        end
        # weak-past tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2)])
            # get past
            weak_past = δ⬇(clock_constraints;normalise=true).past
            @debug string("↓($(string(clock_constraints))) = $(string(weak_past))")

            # base test
            debug_test(clock_valuations,weak_past,true)

            # time step 2
            TimeStep!(clock_valuations,2)
            debug_test(clock_valuations,weak_past,false)

            # reset
            ResetClocks!(clock_valuations)
            debug_test(clock_valuations,weak_past,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,weak_past,true)

            @info "weak-past equality constraint tests passed."
        end
    end
    # diagonal constraints
    begin
        clock_constraints = δ(:deq, "x", "y", 3)
        # simple tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2),("y",4)])
            @debug string("evaluating $(string(clock_constraints))")

            # base test
            debug_test(clock_valuations,clock_constraints,false)

            # time step 2
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,clock_constraints,false)

            # reset
            ResetClocks!(clock_valuations,"y")
            debug_test(clock_valuations,clock_constraints,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,clock_constraints,true)

            @info "diagonal constraint tests passed."
        end
        # weak-past tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2),("y",4)])
            # get past
            weak_past = δ⬇(clock_constraints;normalise=true).past
            @debug string("↓($(string(clock_constraints))) = $(string(weak_past))")

            # base test
            debug_test(clock_valuations,weak_past,false)


            # time step 2
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,weak_past,false)

            # reset
            ResetClocks!(clock_valuations,"y")
            debug_test(clock_valuations,weak_past,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,weak_past,true)

            @info "weak-past diagonal constraint tests passed."
        end
    end
    # greater-than constraints
    begin
        clock_constraints = δ(:gtr, "x", 3)
        # simple tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2)])
            @debug string("evaluating $(string(clock_constraints))")

            # base test
            debug_test(clock_valuations,clock_constraints,false)

            # time step 2
            TimeStep!(clock_valuations,2)
            debug_test(clock_valuations,clock_constraints,true)


            # reset
            ResetClocks!(clock_valuations)
            debug_test(clock_valuations,clock_constraints,false)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,clock_constraints,false)

            # time step 1
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,clock_constraints,true)

            @info "simple greater-than constraint tests passed."
        end
        # weak-past tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2)])
            # get past
            weak_past = δ⬇(clock_constraints;normalise=true).past
            @debug string("↓($(string(clock_constraints))) = $(string(weak_past))")

            # base test
            debug_test(clock_valuations,weak_past,true)

            # time step 2
            TimeStep!(clock_valuations,2)
            debug_test(clock_valuations,weak_past,true)

            # reset
            ResetClocks!(clock_valuations)
            debug_test(clock_valuations,weak_past,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,weak_past,true)

            @info "weak-past greater-than constraint tests passed."
        end
    end
    # conjunctive constraints
    begin
        a = δ(:eq, "x", 3)
        b = δ(:deq, "y", "z", 3)
        clock_constraints = δ(:and, a, b)
        # simple tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2),("y",2),("z",4)])
            @debug string("evaluating $(string(clock_constraints))")

            # base test
            debug_test(clock_valuations,clock_constraints,false)

            # time step 2
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,clock_constraints,false)

            # reset {x,z}
            ResetClocks!(clock_valuations,["x","z"])
            debug_test(clock_valuations,clock_constraints,false)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,clock_constraints,true)

            @info "conjunctive constraint tests passed."
        end
        # weak-past tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2),("y",2),("z",4)])
            # get past
            weak_past = δ⬇(clock_constraints;normalise=true).past
            @debug string("↓($(string(clock_constraints))) = $(string(weak_past))")

            # base test
            debug_test(clock_valuations,weak_past,false)

            # time step 2
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,weak_past,false)

            # reset {x,z}
            ResetClocks!(clock_valuations,["x","z"])
            debug_test(clock_valuations,weak_past,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,weak_past,true)

            @info "weak-past conjunctive constraint tests passed."
        end
    end
    # disjunctive constraints
    begin
        a = δ(:eq, "x", 3)
        b = δ(:deq, "y", "z", 3)
        clock_constraints = δ(:or, a, b)
        # simple tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2),("y",2),("z",4)])
            @debug string("evaluating $(string(clock_constraints))")

            # base test
            debug_test(clock_valuations,clock_constraints,false)

            # time step 2
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,clock_constraints,true)

            # reset {x,z}
            ResetClocks!(clock_valuations,["x","z"])
            debug_test(clock_valuations,clock_constraints,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,clock_constraints,true)

            @info "disjunctive constraint tests passed."
        end
        # weak-past tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2),("y",2),("z",4)])
            # get past
            weak_past = δ⬇(clock_constraints;normalise=true).past
            @debug string("↓($(string(clock_constraints))) = $(string(weak_past))")

            # base test
            debug_test(clock_valuations,weak_past,true)

            # time step 2
            TimeStep!(clock_valuations,1)
            debug_test(clock_valuations,weak_past,true)

            # reset
            ResetClocks!(clock_valuations,["x","z"])
            debug_test(clock_valuations,weak_past,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,weak_past,true)

            # reset
            ResetClocks!(clock_valuations,"y")
            debug_test(clock_valuations,weak_past,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,weak_past,false)

            @info "weak-past disjunctive constraint tests passed."
        end
    end
    # bounded constraints
    begin
        clock_constraints = δ(:and, δ(:geq, "x", 3), δ(:not, δ(:geq, "x", 5)))
        # simple tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2)])
            @debug string("evaluating $(string(clock_constraints))")

            # base test
            debug_test(clock_valuations,clock_constraints,false)

            # time step 2
            TimeStep!(clock_valuations,2)
            debug_test(clock_valuations,clock_constraints,true)

            # time step 3
            TimeStep!(clock_valuations,2)
            debug_test(clock_valuations,clock_constraints,false)

            @info "simple bounded constraint tests passed."
        end
        # weak-past tests
        begin
            # fresh valuations
            clock_valuations = ν([("x",2)])
            # get past
            weak_past = δ⬇(clock_constraints;normalise=true).past
            @debug string("↓($(string(clock_constraints))) = $(string(weak_past))")

            # base test
            debug_test(clock_valuations,weak_past,true)

            # time step 2
            TimeStep!(clock_valuations,2)
            debug_test(clock_valuations,weak_past,true)

            # time step 3
            TimeStep!(clock_valuations,3)
            debug_test(clock_valuations,weak_past,false)

            @info "weak-past bounded constraint tests passed."
        end
    end
    @info "all clock constraint tests passed."
end

# session-type tests
begin
    # simple types
    simple_send = Interact(:send, ("a"), δ(:eq, "x", 2), λ(), End())
    simple_recv = Interact(:recv, ("b"), δ(:gtr, "x", 2), λ(), End())
    simple_choice = Choice([simple_send,simple_recv])

    simple_recursion = μ("r",Interact(simple_send,α("r")))

    # duality
    begin
        # interact 
        begin
            function debug_test(interact) 
                @debug "$(string(interact.type)) =(dual)= $(string(interact.dual))"
                @test dual(interact.type.direction)==interact.dual.direction
            end

            # send
            debug_test(Duality(simple_send))
            
            # recv
            debug_test(Duality(simple_recv))
            
            @info "interaction type duality tests passed."
        end
        # choice
        begin
            choice = Duality(simple_choice)
            @debug "$(string(choice.type)) =(dual)= $(string(choice.dual))"

            # for each interaction in choice, there must be an aciton with the opposite direction but same label in dual
            for interact in choice.type
                dual_interact = get(choice.dual,interact,false)
                # something must have been returned
                @test !(dual_interact isa Bool)
                @test !(dual_interact==false)
                # check direction are dual
                @test dual(interact.direction)==dual_interact.direction
            end

            @info "choice type duality tests passed."
        end
        @info "all type duality tests passed."
    end
end

# configuration transitions
begin
    # simple types
    send_a = Interact(:send, ("a"), δ(:eq, "x", 2), λ(["x"]), End())
    recv_b = Interact(:recv, ("b"), δ(:gtr, "x", 2), λ(), End())
    recv_c = Interact(:recv, ("c"), δ(:and, δ(:geq, "y", 3), δ(:not, δ(:geq, "y", 5))), λ(), End())

    # recursive types
    recursive_choice = Choice([Interact(send_a,α("r")),recv_b,recv_c])
    recursive_type = μ("r",recursive_choice)

    # clock valuations
    valuations = ν([("y",1)])

    # configurations
    local_configuration = Local(valuations, recursive_type)

    # function to print out
    show_debug(context,config) = @debug "$(context):\n$(string(config,:full,:expand,:str))."

    # evaluate tests
    begin
        function evaluation_tests(configuration,actionable)
            evaluation = Evaluate!(configuration)
            show_debug("configuration evaluation",configuration)
            @debug "$(string(evaluation))."
            @test evaluation.actionable==actionable
            return evaluation
        end
        
        # single interaction
        begin
            # base case (clocks=0)
            begin
                evaluation = evaluation_tests(Local(ν([("x",0)]),send_a),true)
                @test evaluation.enabled==false
                @test evaluation.future_en==true
            end

            # x=2
            begin
                evaluation = evaluation_tests(Local(ν([("x",2)]),send_a),true)
                @test evaluation.enabled==true
                @test evaluation.future_en==true
            end

            # x=3
            begin
                evaluation = evaluation_tests(Local(ν([("x",3)]),send_a),true)
                @test evaluation.enabled==false
                @test evaluation.future_en==false
            end

            @info "single interaction evaluation tests passed."
        end
        # recursive choice
        begin
            # fresh copy 
            config = deepcopy(local_configuration)

            # base case
            begin
                evaluation = evaluation_tests(config,true)
                @test evaluation.enabled===nothing
                @test evaluation.future_en===nothing
            end

            # unfold
            Transition!(config,:unfold)
            begin
                evaluation = evaluation_tests(config,true)
                @test evaluation.enabled==false
                @test evaluation.future_en==true
                @debug "enabled: $(string(evaluation.interact_en))"
                @debug "future enabled: $(string(evaluation.interact_fe))"

                @test in(Action(:send, Msg("a")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("b")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("c")), evaluation.interact_fe)
            end
            
            # initial step, time step 2
            Transition!(config,:t,2)
            begin
                evaluation = evaluation_tests(config,true)
                @test evaluation.enabled==true
                @test evaluation.future_en==true
                @debug "enabled: $(string(evaluation.interact_en))"
                @debug "future enabled: $(string(evaluation.interact_fe))"
                
                @test in(Action(:send, Msg("a")), evaluation.interact_en)
                @test !in(Action(:recv, Msg("b")), evaluation.interact_en)
                @test in(Action(:recv, Msg("c")), evaluation.interact_en)

                @test in(Action(:send, Msg("a")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("b")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("c")), evaluation.interact_fe)
            end

            # take action a
            Transition!(config,:send,"a")

            # unfold
            Transition!(config,:unfold)
            begin
                evaluation = evaluation_tests(config,true)
                @test evaluation.enabled==true
                @test evaluation.future_en==true
                @debug "enabled: $(string(evaluation.interact_en))"
                @debug "future enabled: $(string(evaluation.interact_fe))"

                @test !in(Action(:send, Msg("a")), evaluation.interact_en)
                @test !in(Action(:recv, Msg("b")), evaluation.interact_en)
                @test in(Action(:recv, Msg("c")), evaluation.interact_en)

                @test in(Action(:send, Msg("a")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("b")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("c")), evaluation.interact_fe)
            end
            
            # initial step, time step 2
            Transition!(config,:t,2)
            begin
                evaluation = evaluation_tests(config,true)
                @test evaluation.enabled==true
                @test evaluation.future_en==true
                @debug "enabled: $(string(evaluation.interact_en))"
                @debug "future enabled: $(string(evaluation.interact_fe))"
                
                @test in(Action(:send, Msg("a")), evaluation.interact_en)
                @test !in(Action(:recv, Msg("b")), evaluation.interact_en)
                @test !in(Action(:recv, Msg("c")), evaluation.interact_en)

                @test in(Action(:send, Msg("a")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("b")), evaluation.interact_fe)
                @test !in(Action(:recv, Msg("c")), evaluation.interact_fe)
            end

            # disable a, time step 1
            Transition!(config,:t,1)
            begin
                evaluation = evaluation_tests(config,true)
                @test evaluation.enabled==true
                @test evaluation.future_en==true
                @debug "enabled: $(string(evaluation.interact_en))"
                @debug "future enabled: $(string(evaluation.interact_fe))"

                @test !in(Action(:send, Msg("a")), evaluation.interact_en)
                @test in(Action(:recv, Msg("b")), evaluation.interact_en)
                @test !in(Action(:recv, Msg("c")), evaluation.interact_en)

                @test !in(Action(:send, Msg("a")), evaluation.interact_fe)
                @test in(Action(:recv, Msg("b")), evaluation.interact_fe)
                @test !in(Action(:recv, Msg("c")), evaluation.interact_fe)
            end
            
            
            @info "recursive choice evaluation tests passed."
        end

        @info "evaluation tests passed."
    end
    # local tests
    begin
        config = deepcopy(local_configuration)
        @debug "local:\n$(string(config,:full,:expand,:str))."

        @info "local configuration transition tests passed."
    end
    # # social tests
    begin
        config = Social(deepcopy(local_configuration))
        @debug "social:\n$(string(config,:full,:expand,:str))."

        @info "social configuration transition tests passed."
    end
    # # system tests
    begin
        config = System(deepcopy(local_configuration))
        @debug "system:\n$(string(config,:full,:expand,:str))."

        @info "system configuration transition tests passed."
    end
    @info "all configuration transition tests passed."
end

# well-formedness rules
begin
    
end
