import Ipaper.sf: st_dims, st_extract
using Shapefile
using MakieLayers
import MakieLayers: imagesc!


st_dims(x::Shapefile.Point) = x.x, x.y

function st_dims(points::Vector{Shapefile.Point})
  x = [p.x for p in points]
  y = [p.y for p in points]
  x, y
end

function st_dims(points::Vector{Tuple{Float64,Float64}})
  x = [p[1] for p in points]
  y = [p[2] for p in points]
  x, y
end


Base.ndims(x::SpatRaster) = ndims(x.A)

function Ipaper.st_extract(ra::AbstractSpatRaster, points::Vector{Tuple{T,T}}; combine=hcat) where {T<:Real}
  inds, locs = st_location(ra, points)
  cols = repeat([:], ndims(ra) - 2)
  lst = [ra.A[i, j, cols...] for (i, j) in locs]
  inds, combine(lst...) #cbind(lst...)
end

function Base.getindex(ra::SpatRaster, ::Colon, ::Colon, k)
  A = ra.A[:, :, k]
  SpatRaster(ra, A)
end

function imagesc!(ax, ra::SpatRaster, args...; kwargs...)
  lon, lat = st_dims(ra)
  imagesc!(ax, lon, lat, ra.A, args...; kwargs...)
end

# find_near(x, )


dist(p1, p2) = sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)

dist(p1, points::AbstractVector) = [dist(p1, p2) for p2 in points]

findnear(p1, points::AbstractVector) = findmin(dist(p1, points))[2]
