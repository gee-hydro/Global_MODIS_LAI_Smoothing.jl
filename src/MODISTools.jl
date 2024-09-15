# module MODISTools
import DataStructures: OrderedDict
using DataFrames
using Ipaper, RTableTools

includet("Zarr.jl")
includet("main_whit.jl")
includet("main_Ipaper.jl")

function getFileInfo()
  dir_root = path_mnt("/mnt/z/MODIS/Terra_LAI_v061_nc/")
  files = dir(dir_root, ".nc\$")

  years = @pipe basename.(files) |> str_extract("\\d{4}") |> parse.(Int, _)
  grids = @pipe basename.(files) |> str_extract(r"(?<=_)\d_\d")
  DataFrame(; year=years, grid=grids, file=files)
end

info = getFileInfo()
all_grids = unique(info.grid)

# 计算lambda的分组
info_group = DataFrame(;
  year_min=[2000, 2005, 2010, 2015, 2018],
  year_max=[2004, 2009, 2014, 2019, 2022]
)

dateInfo = fread("data/MODIS_LAI_dateInfo.csv")
dateInfo = dateInfo[[1:814; 816:end], :]
