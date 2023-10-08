# module MODISTools

includet("MFDataset.jl")
includet("mapslices_3d.jl")
includet("main_whit.jl")
includet("zarr.jl")



using Terra
using DataFrames
using RTableTools

function nc_st_bbox(file)
  nc_open(file) do nc
    lat = nc[r"lat"][:]
    lon = nc[r"lon"][:]
    st_bbox(lon, lat)
  end
end

function getFileInfo()
  dir_root = "z:/MODIS/Terra_LAI_v061_nc/"
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
