using YAXArrays
using Zarr
import Zarr: ConcurrentRead, NoCompressor, BloscCompressor, ZlibCompressor
using DiskArrays: GridChunks


Zarr.store_read_strategy(::DirectoryStore) = ConcurrentRead(Zarr.concurrent_io_tasks[])
## 采用Zarr保存数据，免去了数据拼接的烦恼

# Base.names(ds::Dataset) = string.(collect(keys(ds.cubes)))
# Base.getindex(ds::Dataset, i) = ds[names(ds)[i]]
# chunksize(ds::Dataset) = chunksize(ds[1])
chunksize(cube) = Cubes.cubechunks(cube)

zarr_rm(p) = rm(p, recursive=true, force=true)

## DirectoryStore
function zarr_group(s::String; overwrite=false, mode="w", kw...)
  if overwrite && isdir(s)
    rm(s, recursive=true, force=true)
  end
  isdir(s) ? zopen(s, mode) : zgroup(s; kw...)
end


"""
    geo_zcreate(p, varname,
        lon, lat, band; chunksize, datatype=Float32)

创建一个geozarr，它可以直接塞给`YAXArrays.open_dataset`

# Return
- `task`: 用于记录哪些chunks运行成功了，运行成功的部分则跳过
"""
function geo_zcreate(p, varname,
  lon, lat, band; chunk_size, datatype=Float32)

  compressor = BloscCompressor(cname="zstd", shuffle=0)
  g = zarr_group(p)
  dims = (length(lon), length(lat), length(band))

  chunks = GridChunks(dims, chunk_size)
  tasks = falses(length(chunks))

  name_t = "band"
  isa(band, Band) && (name_t = "Band")
  isa(band, Ti) && (name_t = "time")

  attr_x = Dict("_ARRAY_DIMENSIONS" => ["lon"], "_ARRAY_OFFSET" => 0)
  attr_y = Dict("_ARRAY_DIMENSIONS" => ["lat"], "_ARRAY_OFFSET" => 0)
  attr_t = Dict("_ARRAY_DIMENSIONS" => [name_t], "_ARRAY_OFFSET" => 0)
  attr_z = Dict("_ARRAY_DIMENSIONS" => [name_t, "lat", "lon"], "task" => tasks)

  x = zcreate(datatype, g, "lon", length(lon); attrs=attr_x)
  y = zcreate(datatype, g, "lat", length(lat); attrs=attr_y)
  t = zcreate(eltype(band), g, name_t, length(band); attrs=attr_t)

  z = zcreate(datatype, g, varname, dims...; chunks=chunk_size, compressor, attrs=attr_z)

  x[:] .= lon
  y[:] .= lat
  t[:] .= band.val
  z
end


function task_finished!(z, ichunk)
  z.attrs["task"][ichunk] = true
  f = "$(z.storage.folder)/$(z.path)/.zattrs"
  open(f, "w") do fid
    JSON.print(fid, z.attrs)
  end
end

## -----------------------------------------------------------------------------
using Terra

function nc_st_bbox(file)
  nc_open(file) do nc
    lat = nc[r"lat"][:]
    lon = nc[r"lon"][:]
    st_bbox(lon, lat)
  end
end
