import Base.show


const Label = String
const ClockValue = UInt8
const TimeValue = UInt8 
const ConstraintValue = UInt8
mutable struct Clock
    label::Label
    value::ClockValue
end

abstract type Constraint end
struct True <: Constraint end
struct Geq <: Constraint 
    clock::Clock
    num::ConstraintValue
end
struct Eq <: Constraint 
    clock::Clock
    num::ConstraintValue
end
struct DiagGeq <: Constraint 
    gtr::Clock
    lsr::Clock
    num::ConstraintValue
end
struct DiagEq <: Constraint 
    gtr::Clock
    lsr::Clock
    num::ConstraintValue
end



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

const Clocks = Array{Clock}
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

function show(val::ClockValue, io::IO = stdout)
    print(io, "Clock value: ", val)
end

function show(clock::Clock, io::IO = stdout)
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

test_clocks = Clocks([Clock("a",0),Clock("b",1),Clock("c",2),Clock("d",3),Clock("e",4),Clock("f",5)])
show(test_clocks)

show(value_of(test_clocks,Label("c")))
println()

test_resets = Resets(["b","d","f"])
show(test_resets)
println()

reset_clocks!(test_clocks,test_resets)
show(test_clocks)

function time_step!(clocks::Clocks,time::TimeValue)
    foreach(c -> c.value += time, clocks)
end

time_step!(test_clocks,TimeValue(3))
show(test_clocks)
println()

