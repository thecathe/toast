# todo

- [ ] in "logical_clocks/constraints/constraint_intersection.jl", check how diagonal constraints should be dealt with. (i think "logical_clocks/constraints/bounds_of_constraints.jl" does not deal with them)
- [ ] in "logical_clocks/constraints/constraint_normalisation.jl" need to extract method refactoring (for :and,:or cases)
- [ ] in "logical_clocks/constraints/constraint_normalisation.jl" add checks for filtering out obsolete constraints (i.e.: (x<3 and x<5)==(x<5), (x>3 or x>5)==(x>3))
- [ ] in "transitions/transitions_social/transition_time.jl" add way of stepping right up until an exclusive lower bound, for receiving action constraints such as (x>5) (or, maybe instead allow tau actions to apply this as well? this usually wouldnt be an issue when the recipient arrives at thsi state before a message is received. hm)
- [ ] overhaul "logical_clocks/constraints/bounds_of_constraints.jl" so that :and and :or constraints are handled separately, with in and: all constraints needing after_clock above lb, and one eq to it (for urgency premise in "transitions/transitions_social/transition_time.jl") and, for or: only one constraint needing after_clock above lb. maybe this requires new function/struct to split constraints into granules and resolve each locally, and then build it up
