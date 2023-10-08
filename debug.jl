includet("src/MFDataset.jl")

indir = path_mnt("/mnt/z/MODIS/Terra_LAI_v061_nc")
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
# 这里是120*30
chunkszie = (240 * 30, 240 * 30, typemax(Int))
m = MFDataset(fs, chunkszie)
v = m[:LAI]
# v = vars[1]

# @time r1 = mapslices_3d(mean, A; parallel=true);
# r2 = mapslices_3d(mean, A; parallel=false)

# add(x, y) = x + y
res = mapslices_3d(mean, m, m.bands[1:1]; )

## 数据保存到zarr
