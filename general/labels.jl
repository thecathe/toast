
import Base.show
import Base.string
import Base.convert
import Base.getindex
import Base.iterate
import Base.push!
import Base.length
import Base.isempty


const Label = String 

abstract type LabelList end

struct Labels <: LabelList
    children::Array{Label}
    distinct::Bool
    Labels() = new(Array{Label}([]))
    Labels(s::String,distinct::Bool=true) = Labels(Array{Label}([s]),distinct)
    Labels(s::T,distinct::Bool=true) where {T<:Array{Any}} = Labels(Array{Label}([Label(l) for l in s]),distinct)
    function Labels(children::Array{Label},distinct::Bool=true) 
        if distinct
            return new(Array{Label}([unique(children)...]),distinct)
        else
            return new(Array{Label}([children...]),distinct)
        end
    end
end

Base.show(l::Labels, io::Core.IO = stdout) = print(io, string(l))
Base.string(l::Labels) = isempty(l) ? string("∅") : string("{", join(l, ", "), "}")

# Base.convert(::Type{Labels}, l::T) where {T<:Array{S} where {S<:String}} = Labels([l...])
# function Base.convert(::Type{Labels}, l::T) where {T<:Array{Any}}
#     @assert isempty(l) "Base.convert Labels, unknown non-empty: ($(typeof(l))) : $(string(l))"
#     return Labels([])
# end
Base.convert(::Type{Array{Label}}, d::T) where {T<:Array{Any}} = Labels([Label(l) for l in d])
# Base.convert(::Type{Labels}, d::T) where {T<:Array{String}} = Labels([d...])

Base.push!(l::Labels, a::Label) = push!(l.children, a)

Base.length(l::Labels) = length(l.children)
Base.isempty(l::Labels) = isempty(l.children)
Base.getindex(l::Labels, i::Int) = getindex(l.children, i)

Base.iterate(l::Labels) = isempty(l) ? nothing : (getindex(l,1), Int(1))
Base.iterate(l::Labels, i::Int) = (i >= length(l)) ? nothing : (getindex(l,i+1), i+1)
