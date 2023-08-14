import Base.show
import Base.string
import Base.iterate
import Base.getindex
import Base.length
import Base.isempty
import Base.convert


const Label = String
const ClockValue = UInt8
const TimeValue = UInt8 
const ConstraintValue = UInt8
mutable struct Clock
    label::Label
    value::ClockValue
end

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
    num::ConstraintValue
    Geq(clock,num) = new(clock, num)
end
struct Eq <: Constraint 
    clock::Label
    num::ConstraintValue
    Eq(clock,num) = new(clock, num)
end
struct DiagGeq <: Constraint 
    gtr::Label
    lsr::Label
    num::ConstraintValue
    DiagGeq(gtr,lsr,num) = new(gtr,lsr, num)
end
struct DiagEq <: Constraint 
    gtr::Label
    lsr::Label
    num::ConstraintValue
    DiagEq(gtr,lsr,num) = new(gtr,lsr, num)
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
    λ::Array{Clock}
    S::SessionType
end


struct Def <: SessionType end
struct Call <: SessionType end

const Choice = Array{Interaction} <: SessionType

# const Clocks = Array{Clock}
mutable struct Clocks 
    children::Array{Clock}
    Clocks(children) = new(children)
end

Base.convert(::Type{δ}, constraint::T) where {T<:Constraint} = δ(constraint)

Base.convert(::Type{Clock}, tup::T) where {T<:Tuple{String,Int}} = Clock(tup[1],tup[2])::Clock
# Base.convert(::Type{Clocks}, vec::T) where {T<:Vector{Clock}} = Clocks([c::Clock for c in vec])::Clocks

Base.length(clocks::Clocks) = length(clocks.children)
Base.isempty(clocks::Clocks) = isempty(clocks.children)
Base.getindex(clocks::Clocks, index::Int) = clocks.children[index]

# iterate(clocks::Clocks, index::Int) ->
Base.iterate(clocks::Clocks) = (isempty(clocks)) ? nothing : (clocks[1], Int(1))
Base.iterate(clocks::Clocks, state::Int)  = (state >= length(clocks) ? nothing : (clocks[state+1], state+1))

const Resets = Array{Label}
const Valuations = Array{ClockValue}
const Queue = Array{Msg}
# const Labels = Array{Label}


function labels(clocks::Clocks)
    return Array{Label}([c.label for c in clocks])
end 

function values(clocks::Clocks)
    return Array{ClockValue}([c.value for c in clocks])
end 

function value_of(clocks::Clocks,label::Label)
    # res contains all values returned for given clock label
    res = values(Clocks([clocks[c] for c in indexin(Array{Label}([label]),labels(clocks)) if !isnothing(c)]))
    # ensure only one value is returned
    @assert !isempty(res) "No clock labelled '$(label)' in:\n$(show(clocks))"
    @assert length(res) == 1 "More than one clock labelled '$(label)' in:\n$(show(clocks))"
    return ClockValue(first(res))
end 
    

function reset_clocks!(clocks::Clocks, resets::Resets)
    # set each clock value to 0 if in resets
    foreach(c -> c.value = (c.label in resets) ? 0 : c.value, clocks)
end

struct Cfg
    valuations::Clocks
    type::SessionType
    queue::Queue
end

function Base.show(label::Label, io::IO = stdout)
    print(io, label)
end

function Base.show(val::ClockValue, io::IO = stdout)
    print(io, "Clock value: ", val)
end

function Base.show(clock::Clock, io::IO = stdout)
    print(io, "Clock ", clock.label, ": ", clock.value)
end

function show(clocks::Clocks, io::IO = stdout)
    println(io, "Clock Valuations: [")
    for c in clocks 
        print("\t") 
        show(c, io) 
        println() 
    end
    println("]")
end

function show(δ::Constraint, io::IO = stdout)
    print(io, string(δ))
end

function string(constraint::δ)
    return string(constraint.child)
end
function show(constraint::δ, io::IO = stdout)
    print(io, string(constraint))
end

function string(::True)
    return string(true)
end

function string(δ::Geq)
    return string(string(δ.clock), "≥", string(δ.num))
end

function string(δ::Eq)
    return string(string(δ.clock), "=", string(δ.num))
end

function string(δ::DiagGeq)
    return string(string(δ.gtr), "-", string(δ.lsr), "≥", string(δ.num))
end

function string(δ::DiagEq)
    return string(string(δ.gtr), "-", string(δ.lsr), "=", string(δ.num))
end

function string(δ::Not)
    return string("¬(", string(δ.child),")")
end

function string(δ::And)
    return string("(", string(δ.lhs), ") ∧ (", string(δ.rhs), ")")
end

test_clocks = Clocks([("a",0),("b",1),("c",2),("d",3),("e",4),("f",5)])
show(test_clocks)
println()
println()

show(value_of(test_clocks,Label("c")))
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



function time_step!(clocks::Clocks,time::TimeValue)
    foreach(c -> c.value += time, clocks)
end

time_step!(test_clocks,TimeValue(3))
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
