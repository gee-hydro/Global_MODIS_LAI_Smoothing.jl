#! julia -t 12 s1_param_lambda.jl
using Revise
includet("src/MODISTools.jl")

indir = path_mnt("/mnt/z/MODIS/Terra_LAI_v061_nc")
fs = [
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2018_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2019_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2020_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2021_2_4.nc"
  "$indir/MOD15A2H_v061-raw2-LAI_240deg_global_2022_2_4.nc"
]
## debug
# m = MFDataset(fs, chunkszie)
# n = m.ntime
# w = zeros(Float32, n)
# interm = interm_whit{Float32}(; n)
# res = mapslices_3d(pixel_cal_lambda, m; n_run=1, method="cv", w, interm)

## 实战
using DataFrames
using RTableTools

dir_root = "z:/MODIS/Terra_LAI_v061_nc/"
files = dir(dir_root, ".nc\$")

dateInfo = fread("data/MODIS_LAI_dateInfo.csv")

years = @pipe basename.(files) |> str_extract("\\d{4}") |> parse.(Int, _)
grids = @pipe basename.(files) |> str_extract(r"(?<=_)\d_\d")

info = DataFrame(; year=years, grid=grids, file=files)

# 计算lambda的分组
info_group = DataFrame(;
  year_min=[2000, 2005, 2010, 2015, 2018],
  year_max=[2004, 2009, 2014, 2019, 2022]
)

all_grids = unique(grids)

for k = 1:5
# k = 5
  year_min, year_max = info_group[k, [:year_min, :year_max]]
  _dateInfo = @pipe dateInfo |> _[(year_min.<=_.year.<=year_max), :]
  dates = _dateInfo.date

  for grid in all_grids
    d = @pipe info |> _[(year_min.<=_.year.<=year_max).&&(_.grid.==grid), :]
    process_whit_chunk(d)
  end
end
