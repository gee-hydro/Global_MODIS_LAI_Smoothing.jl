using Base.Threads
using ProgressMeter, JSON
using NCDatasets
using NCDatasets.DiskArrays: GridChunks

using Zarr
import Zarr: store_read_strategy, SequentialRead, ConcurrentRead
import Zarr: NoCompressor, BloscCompressor, ZlibCompressor


chunksize(z::ZArray) = z.metadata.chunks
GridChunks(z::ZArray) = GridChunks(size(z), chunksize(z))

Zarr.store_read_strategy(::DirectoryStore) = ConcurrentRead(Zarr.concurrent_io_tasks[])

zarr_rm(p) = rm(p, recursive=true, force=true)

function zarr_group(s::String; overwrite=false, mode="w", kw...)
  if overwrite && isdir(s)
    rm(s, recursive=true, force=true)
  end
  isdir(s) ? zopen(s, mode) : zgroup(s; kw...)
end

# true : 运行结束
# false: 未结束
chunk_task_finished(z::ZArray, ichunk) = z.attrs["task"][ichunk]

function chunk_task_finished!(z::ZArray, ichunk, value=true)
  z.attrs["task"][ichunk] = value
  f = "$(z.storage.folder)/$(z.path)/.zattrs"
  open(f, "w") do fid
    JSON.print(fid, z.attrs)
  end
end


# include("zarr_IO.jl")
# include("geo_zarr.jl")

using Ipaper.sf
import Ipaper.sf: st_bbox, st_dims

st_bbox(z::ZArray) = bbox(z.attrs["bbox"]...)
st_dims(z::ZArray) = bbox2dims(st_bbox(z); size=size(z)[1:2])


export chunksize, GridChunks
export zarr_rm, zarr_group

export chunk_task_finished, chunk_task_finished!
export write_zarr, read_zarr
export geo_zarr
