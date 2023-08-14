module TOAST

import Base.show
import Base.string
import Base.iterate
import Base.getindex
import Base.length
import Base.isempty
import Base.convert

module General

    export Label 
    const Label = String

    function Base.show(label::Label, io::IO = stdout)
        print(io, label)
    end


end

module LogicalClocks

    using ..General
    export Clock, Label, TimeValue, Clocks, Resets, ClockValue
    export labels, values, value_of!, reset_clocks!, time_step!


    const TimeValue = UInt8 
    const Resets = Array{Label}


    const ClockValue = UInt8
    mutable struct Clock
        label::Label
        value::ClockValue
    end

    # const Clocks = Array{Clock}
    mutable struct Clocks 
        children::Array{Clock}
        Clocks(children) = new(children)
    end


    Base.convert(::Type{Array{Clock}}, clocks::T) where {T<:Clocks} = Array{Clock}(clocks.children)
    Base.convert(::Type{Clock}, tup::T) where {T<:Tuple{String,Int}} = Clock(tup[1],tup[2])::Clock
    Base.convert(::Type{TimeValue}, int::T) where {T<:Int} = TimeValue(unsigned(int))

    Base.length(clocks::Clocks) = length(clocks.children)
    Base.isempty(clocks::Clocks) = isempty(clocks.children)
    Base.getindex(clocks::Clocks, index::Int) = clocks.children[index]

    Base.push!(clocks::Clocks, clock::Clock) = push!(clocks.children, clock)

    Base.iterate(clocks::Clocks) = (isempty(clocks)) ? nothing : (clocks[1], Int(1))
    Base.iterate(clocks::Clocks, state::Int)  = (state >= length(clocks) ? nothing : (clocks[state+1], state+1))

    function labels(clocks::Clocks)
        return Array{Label}([c.label for c in clocks])
    end 

    function values(clocks::Clocks)
        return Array{ClockValue}([c.value for c in clocks])
    end 

    # initialises if not exist
    function value_of!(clocks::Clocks,label::Label)
        res = value_of(clocks, label)
        if isempty(res)
            # show(string("value_of! ", label, " was not found!\n"))
            push!(clocks, Clock(label, 0))
        end
        return ClockValue(0)
    end

    # does not initialise
    function value_of(clocks::Clocks,label::Label)
        # res contains all values returned for given clock label
        res = values(Clocks([clocks[c] for c in indexin(Array{Label}([label]),labels(clocks)) if !isnothing(c)]))
        # @assert !isempty(res) "No clock labelled '$(label)' in:\n$(show(clocks))"
        # ensure only one value is returned
        @assert length(res) <= 1 "More than one clock labelled '$(label)' in:\n$(show(clocks))"
        return (isempty(res)) ? [] : ClockValue(first(res))
    end 


    function reset_clocks!(clocks::Clocks, resets::Resets)
        # set each clock value to 0 if in resets
        foreach(c -> c.value = (c.label in resets) ? 0 : c.value, clocks)
    end

    function Base.show(val::ClockValue, io::IO = stdout)
        print(io, "Clock value: ", val)
    end

    function Base.show(clock::Clock, io::IO = stdout)
        print(io, string(clock))
    end

    function Base.show(clocks::Clocks, io::IO = stdout)
        print(io, string(clocks))
    end

    function Base.string(clocks::Clocks) 
        return string([string(c) for c in clocks])
    end 

    function Base.string(clock::Clock) 
        return string("", string(clock.label), ": ", string(clock.value))
    end 

    time_step!(clocks::Clocks,time::Int) = time_step!(clocks, TimeValue(time))
    function time_step!(clocks::Clocks,time::TimeValue)
        foreach(c -> c.value += time, clocks)
    end

end

module ClockConstraints


    using ..General
    using ..LogicalClocks
    export Constraint, ConstraintValue,δ,True,Geq,Eq,DiagGeq,DiagEq,Not,Not!, And, constrains, evaluate

    const ConstraintValue = UInt8
    abstract type Constraint end

    mutable struct δ 
        child::Constraint
        δ(child) = new(child)
    end

    struct True <: Constraint
        True() = new(true::Bool)
    end
    struct Geq <: Constraint 
        clock::Label
        value::ConstraintValue
        Geq(clock,value) = new(clock, value)
    end
    struct Eq <: Constraint 
        clock::Label
        value::ConstraintValue
        Eq(clock,value) = new(clock, value)
    end
    struct DiagGeq <: Constraint 
        gtr::Label
        lsr::Label
        value::ConstraintValue
        DiagGeq(gtr,lsr,value) = new(gtr,lsr, value)
    end
    struct DiagEq <: Constraint 
        gtr::Label
        lsr::Label
        value::ConstraintValue
        DiagEq(gtr,lsr,value) = new(gtr,lsr, value)
    end
    # struct Not{Constraint} end
    struct And <: Constraint 
        lhs::δ
        rhs::δ
        And(lhs,rhs) = new(lhs,rhs)
    end

    function Not!(constraint::δ)
        constraint.child=Not(constraint.child)
    end

    struct Not <: Constraint 
        child::δ
        Not(child) = new(child)
    end
    # Not(c::Constraint) = convert(Neg, c)
    # convert(::Type{Neg}, x::Constraint) where {Neg<:Constraint} = Constraint(x)::Constraint


    Base.convert(::Type{δ}, constraint::T) where {T<:Constraint} = δ(constraint)

    function Base.show(δ::Constraint, io::IO = stdout)
        print(io, string(δ))
    end

    function Base.string(constraint::δ)
        return string(constraint.child)
    end
    function Base.show(constraint::δ, io::IO = stdout)
        print(io, string(constraint))
    end

    function Base.string(::True)
        return string(true)
    end

    function Base.string(δ::Geq)
        return string(string(δ.clock), "≥", string(δ.value))
    end

    function Base.string(δ::Eq)
        return string(string(δ.clock), "=", string(δ.value))
    end

    function Base.string(δ::DiagGeq)
        return string(string(δ.gtr), "-", string(δ.lsr), "≥", string(δ.value))
    end

    function Base.string(δ::DiagEq)
        return string(string(δ.gtr), "-", string(δ.lsr), "=", string(δ.value))
    end

    function Base.string(δ::Not)
        return string("¬(", string(δ.child),")")
    end

    function Base.string(δ::And)
        return string("(", string(δ.lhs), ") ∧ (", string(δ.rhs), ")")
    end

    
    constrains(constraint::δ) = constrains(constraint.child)
    constrains(constraint::Geq) = constraint.clock
    constrains(constraint::Eq) = constraint.clock
    constrains(constraint::DiagGeq) = constraint.clock
    constrains(constraint::DiagEq) = constraint.clock
    constrains(constraint::Not) = constraint.child
    constrains(constraint::And) = [constrains(constraint.lhs); constrains(constraint.rhs)]

    evaluate(clocks::Clocks,constraint::δ) = evaluate(clocks,constraint.child)
    evaluate(clocks::Clocks,constraint::And) = evaluate(clocks,constraint.lhs) && evaluate(clocks,constraint.rhs)
    evaluate(clocks::Clocks,constraint::Not) = !evaluate(clocks,constraint.child)

    evaluate(clocks::Clocks,constraint::Geq) = (value_of!(clocks, constraint.clock) >= constraint.value) ? true : false
    evaluate(clocks::Clocks,constraint::Eq) = (value_of!(clocks, constraint.clock) == constraint.value) ? true : false
    evaluate(clocks::Clocks,constraint::DiagGeq) = ((value_of!(clocks, constraint.gtr) - value_of!(clocks, constraint.lsr)) >= constraint.value) ? true : false
    evaluate(clocks::Clocks,constraint::DiagEq) = ((value_of!(clocks, constraint.gtr) - value_of!(clocks, constraint.lsr)) == constraint.value) ? true : false

    

end

module SessionTypes

    using ..General
    using ..LogicalClocks
    using ..ClockConstraints
    export Term, Send, Recv, Comm, SessionType, PayLoad,Delegation, Data,Msg,Action,Interaction,Def,Call,Choice

    abstract type SessionType end

    struct Term <: SessionType end

    abstract type Comm end
    struct Send <: Comm end
    struct Recv <: Comm end

    abstract type PayLoad end
    struct Delegation <: PayLoad end
    struct Data <: PayLoad end

    struct Msg{PayLoad}
        label::Label
        payload::PayLoad
    end


    struct Action{Comm}
        comm::Comm
        msg::Msg
    end

    struct Interaction <: SessionType 
        action::Action
        δ::Matrix{Constraint}
        λ::Resets
        S::SessionType
    end


    struct Def <: SessionType end
    struct Call <: SessionType end

    const Choice = Array{Interaction} <: SessionType

end

module Configurations

    using ..General
    using ..LogicalClocks
    using ..SessionTypes

    export Cfg, Queue, Valuations
    const Queue = Array{Msg}
    # const Valuations = Array{ClockValue}

    struct Cfg
        valuations::Clocks
        type::SessionType
        queue::Queue
    end

end

# using .General
# using .LogicalClocks
# using .ClockConstraints
# using .SessionTypes
# using .Configurations

import .General.Label

import .LogicalClocks.Clocks
import .LogicalClocks.Resets
import .LogicalClocks.value_of!
import .LogicalClocks.reset_clocks!
import .LogicalClocks.time_step!

import .ClockConstraints.δ
import .ClockConstraints.Geq
import .ClockConstraints.Eq
import .ClockConstraints.DiagGeq
import .ClockConstraints.DiagEq
import .ClockConstraints.Not
import .ClockConstraints.Not!
import .ClockConstraints.And
import .ClockConstraints.constrains
import .ClockConstraints.evaluate
# import .SessionTypes
# import .Configurations





test_clocks = Clocks([("a",0),("b",1),("c",2),("d",3),("e",4),("f",5)])
show(test_clocks)
println()
println()

show(value_of!(test_clocks,Label("c")))
println()
println()

test_resets = Resets(["b","d","f"])
show(test_resets)
println()
println()

reset_clocks!(test_clocks,test_resets)
show(test_clocks)
println()
println()



time_step!(test_clocks,3)
show(test_clocks)
println()
println()


constraint_a = δ(Geq("a",3))
show(constraint_a)
println()
println()


show(Not!(constraint_a))
println()
println()

constraint_b = δ(DiagEq("b", "c", 5))
show(constraint_b)
println()
println()

show(And(constraint_a,constraint_b))
println()
println()

# show(evaluate(Clocks([("a",4)]), constraint_a))
# println()
# show(evaluate(Clocks([("a",9)]), constraint_a))
# println()
# println()

show(evaluate(Clocks([("a",1)]), Eq("a",2))) # false
println()

show(evaluate(Clocks([("b",1)]), Eq("a",1))) # false
println()

show(evaluate(Clocks([("b",1)]), Eq("a",0))) # true
println()

show(evaluate(Clocks([("a",1),("b",2)]), And(Eq("a",1),Eq("b",2)))) # true 
println()

show(evaluate(Clocks([("a",1)]), And(Eq("a",0),Eq("b",0)))) # true 
println()

end