# MFDataset
using Revise
cd("Z:/GitHub/jl-spatial/Whittaker2.jl/scripts/Project_Global_LAI_smoothing")
includet("../src/MODISTools.jl")

indir = path_mnt("/mnt/z/MODIS/Terra_LAI_v061_nc")
fs = [
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2018_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2019_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2020_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2021_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2022_2_4.nc"
]

## debug
chunk_size = (240 * 10, 240 * 10, 10000)
m = MFDataset(fs, chunk_size)

# n = m.ntime
# w = zeros(Float32, n)
# interm = interm_whit{Float32}(; n)
# res = mapslices_3d(pixel_cal_lambda, m; n_run=1, method="cv", w, interm)
