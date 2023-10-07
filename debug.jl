include("src/MFDataset.jl")
## 加一个Base.show function
# Base.getindex(m::MFDataset, i, j) = map(nc -> nc[i, j], m.nc)

indir = "/mnt/z/MODIS/Terra_LAI_v061_nc"
fs = [
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2018_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2019_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2020_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2021_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2022_2_4.nc"
]

## 设计成功
# @show hello(;fs)
# nc = nc_open.(fs)
chunkszie = (2400, 2400, typemax(Int))
m = MFDataset(fs, chunkszie)
vars = m[:LAI]
v = vars[1]

# 设计一个chunks
using DiskArrays: GridChunks

r = vars[1:10, 1:10, dims=3]
# 设计一个chunks
# GridChunks(size(v), (240, 240, 1_000_000))
# chunking(var)
