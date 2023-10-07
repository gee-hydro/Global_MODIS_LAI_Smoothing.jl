using NCDatasets
using NCDatasets: CFVariable
using DiskArrays: GridChunks
using NetCDFTools
using NetCDF
using Parameters


@with_kw mutable struct MFDataset
  fs::Vector{String}
  nc::Vector{NCDataset{Nothing}} = nc_open.(fs)
  bands = nc_bands(nc[1])
  size = size(nc[1][bands[1]]) # variable dimension size

  # chunksize = [240, 240] * 10
  chunksize = ntuple(x -> typemax(Int), length(size)) # 默认不设chunks
  chunks = GridChunks(size, chunksize)
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
  r = map(var -> var[i, j, :], v.vars)
  cat(r...; dims)
end

export MFDataset, MFVariable
