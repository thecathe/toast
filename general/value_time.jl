struct TimeValue 
    value::T where {T<:Real}
    function TimeValue(value::Number)
        @assert value>=0 "Time values must be greater or equal to 0: '$(value)' is invalid."
        new(value)
    end
end
Base.string(t::TimeValue) = string(t.value)