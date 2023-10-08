using NCDatasets
using NCDatasets: CFVariable
using DiskArrays: GridChunks
using NetCDFTools
using NetCDF
using Parameters
using ProgressMeter
using Ipaper

## 加一个Base.show function
@with_kw mutable struct MFDataset
  fs::Vector{String}
  nc::Vector{NCDataset{Nothing}} = nc_open.(fs)
  bands = nc_bands(nc[1])

  sizes = map(nc -> size(nc[bands[1]]), nc) # variable dimension size
  ntime = sum(map(last, sizes)) # 时间在最后一维

  # chunksize = [240, 240] * 10
  chunksize = ntuple(x -> typemax(Int), length(sizes[1])) # 默认不设chunks
  chunks = GridChunks(sizes[1], chunksize)
end
MFDataset(fs) = MFDataset(; fs)
MFDataset(fs, chunksize) = MFDataset(; fs, chunksize)

mutable struct MFVariable{T,N}
  vars::Vector{CFVariable{T,N}}
end

nc_close(m::MFDataset) = nc_close.(m.nc)

function Base.getindex(m::MFDataset, key::Union{String,Symbol})
  # return a MFVariable
  vars = map(nc -> nc[key], m.nc)
  var = vars[1]
  MFVariable{eltype(var),ndims(var)}(vars)
end

Base.getindex(v::MFVariable, i) = v.vars[i]

function Base.getindex(v::MFVariable{T,3}, i, j; dims=3) where {T}
  ntime = map(x -> size(x, 3), v.vars) |> sum
  nlon, nlat = size(v.vars[1])[1:2]
  i != Colon() && (nlon = length(i))
  j != Colon() && (nlat = length(j))

  res = zeros(T, nlon, nlat, ntime)
  i_beg = 0
  @inbounds for var in v.vars
    _ntime = size(var, 3)
    inds = (i_beg + 1):(i_beg+_ntime)
    # @show inds
    res[:, :, inds] .= var[i, j, :]
    i_beg += _ntime
  end
  res
  # res = map(var -> var[i, j, :], v.vars)
  # cat(res...; dims)
end


export MFDataset, MFVariable