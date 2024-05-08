module RecVarEnv

    import Base.show
    import Base.string

    import Base.length
    import Base.isempty
    
    import Base.setindex!
    import Base.getindex
    import Base.iterate

    import Base.keys
    import Base.in
    import Base.get
    import Base.findall

    using ..LogicalClocks
    using ..SessionTypes
    
    export RecEnv
    mutable struct RecEnv
        children::Dict{α,δ}
        RecEnv() = new(Dict{α,δ}())
        function RecEnv(children::Array{Tuple{T,δ}}) where {T<:Union{String,α}}
            builder = RecEnv()
            for child in children
                # check if actual α or just label
                if child[1] isa String
                    builder[α(child[1])] = child[2]
                else
                    builder[child[1]] = child[2]
                end
            end
            return builder
        end
    end

    Base.string(env::RecEnv, args...) = isempty(env) ? "∅" : string(env.children)
    Base.string(env::Dict{α,δ}, args...) = isempty(env) ? "∅" : string(join(["$(string(var)):($(string(env[var])))" for var in keys(env)], ", "))

    function Base.in(type::α,env::RecEnv)
        isin = get(env, type, false)
        if isin isa Bool
            return isin
        else
            return true
        end
    end

    Base.keys(env::RecEnv) = keys(env.children)

    Base.length(env::RecEnv) = length(env.children)
    Base.isempty(env::RecEnv) = isempty(env.children)
    function Base.getindex(env::RecEnv, i::Int) 
        @info "env: $(string(env))"
        ks = keys(env.children) 
        @info "keys: $(string(ks))"
        env[ks[i]]
    end
    Base.setindex!(env::RecEnv, constraints::δ, var::α) = setindex!(env.children, constraints, var)

    Base.iterate(env::RecEnv) = isempty(env) ? nothing : (keys(env)[1], Int(1))
    Base.iterate(env::RecEnv, i::Int) = (i >= length(keys(env))) ? nothing : (keys(env)[i+1], i+1)

    "Get rec var taht exactly matches v."
    Base.get(env::RecEnv,v::α,default=nothing) = get(env,v.identity,v.iteration,default)
    
    "Get rec var with matching label."
    function Base.get(env::RecEnv,id::String,default=nothing)
        for var in env
            if var.identity==id
                return var
            end
        end
        return default
    end
    
    "Get rec var with matching label and iteration number."
    function Base.get(env::RecEnv,id::String,it::UInt8,default=nothing)
        for var in keys(env)
            if var.identity==id && var.iteration==it
                return var
            end
        end
        return default
    end

    "Findall premises that match the label."
    function Base.findall(env::RecEnv,label::String)
        collection = Array{α}([])
        for var in env
            if var.identity==label
                push!(collection,var)
            end
        end
        return collection
    end

end