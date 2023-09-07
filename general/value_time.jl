struct UnitOfTime 
    value::T where {T<:Real}
    function UnitOfTime(value::Number)
        @assert value>=0 "Time values must be greater or equal to 0: '$(value)' is invalid."
        new(value)
    end
end
Base.string(t::UnitOfTime) = string(t.value)