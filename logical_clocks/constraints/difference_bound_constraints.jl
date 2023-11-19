module DifferenceBoundConstraints

    import Base.string

    import ..LogicalClocks.Num

    export DBC#, sortDBC

    supported_zones = [:eq,:geq,:leq,:gtr,:les]

    struct DBC
        zone::Symbol
        # clock::String
        constant::Num

        DBC(t::T) where {T<:Tuple{Symbol,Num}} = DBC(t[1],t[2])
        # DBC(t::T) where {T<:Tuple{Symbol,String,Num}} = DBC(t[1],t[2],t[3])

        function DBC(zone::Symbol,constant::Num)
        # function DBC(zone::Symbol,clock::String,constant::Num)
            @assert zone ∈ supported_zones "DBC, zone unexpected: $(string(zone))."
            @assert constant>=0 "DBC, constant must be ≥ 0, not: $(string(constant))."
            new(zone,constant)
            # new(zone,clock,constant)
        end

    end

    Base.string(dbc::DBC) = string("($(string(dbc.zone)), $(string(dbc.constant)))")

    # function sortDBC(a::DBC,b::DBC)
    # end

end