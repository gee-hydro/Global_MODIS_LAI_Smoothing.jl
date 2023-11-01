using Ipaper
import DataStructures: OrderedDict


function Base.merge(xs::Vector{<:NamedTuple}; keys=nothing)
  keys === nothing && (keys = Base.keys(xs[1]))
  values = [vcat(map(x -> x[name], xs)...) for name in keys]
  (; zip(keys, values)...)
end

## extract data
function rm_empty(x::Vector)
  inds = findall(!isnothing, x)
  inds, x[inds]
end

# function findnear(values, x)
#   _, i = findmin(abs.(values .- x))
#   values[i], i
# end


dist(p1, p2) = sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)

dist(p1, points::AbstractVector) = [dist(p1, p2) for p2 in points]

findnear(p1, points::AbstractVector) = findmin(dist(p1, points))[2]
