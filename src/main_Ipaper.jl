import Ipaper.sf: st_dims, st_extract, st_bbox, rast, st_resample
using Shapefile

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


dist(p1, p2) = sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)

dist(p1, points::AbstractVector) = [dist(p1, p2) for p2 in points]

findnear(p1, points::AbstractVector) = findmin(dist(p1, points))[2]



using YAXArrays

Base.names(ds::YAXArrays.Dataset) = string.(collect(keys(ds.cubes))) |> sort
Base.getindex(ds::YAXArrays.Dataset, i) = ds[names(ds)[i]]

# Terra.chunksize(ds::YAXArrays.Dataset) = chunksize(ds[1])
# Terra.chunksize(c) = Cubes.cubechunks(c)
st_bbox(ds::YAXArrays.Dataset) = st_bbox.(get_zarr(ds)) # multiple

function get_zarr(ds::YAXArrays.Dataset)
  vars = names(ds)
  map(var -> begin
      A = ds[var].data
      b = st_bbox(A)
      rast(A, b)
    end, vars)
end

# 哪个grid被选中了
function which_grid(ds::YAXArrays.Dataset, (lon, lat))
  zs = get_zarr(ds)
  bs = st_bbox.(zs)
  inds = in_bbox(bs, (lon, lat)) |> findall
  !isempty(inds) ? names(ds)[inds[1]] : nothing
end

function Ipaper.SpatRaster(f::String)
  # lon, lat = st_dims(f)
  b = st_bbox(f)
  A = read_gdal(f)
  SpatRaster(A, b)
end

function st_resample(ra::SpatRaster; fact=10)
  A = resample2(ra.A; fact, deepcopy=true)
  SpatRaster(A, ra.b)
end
