using YAXArrays
using Zarr
import Zarr: ConcurrentRead, NoCompressor, BloscCompressor, ZlibCompressor

Zarr.store_read_strategy(::DirectoryStore) = ConcurrentRead(Zarr.concurrent_io_tasks[])
## 采用Zarr保存数据，免去了数据拼接的烦恼

# Base.names(ds::Dataset) = string.(collect(keys(ds.cubes)))
# Base.getindex(ds::Dataset, i) = ds[names(ds)[i]]
# chunksize(ds::Dataset) = chunksize(ds[1])
chunksize(cube) = Cubes.cubechunks(cube)

## DirectoryStore
function zarr_group(s::String; overwrite=false, mode="w", kw...)
  if overwrite && isdir(s)
    rm(s, recursive=true, force=true)
  end
  isdir(s) ? zopen(s, mode) : zgroup(s; kw...)
end


