using Ipaper
using NetCDFTools
using Distributed
using DataFrames
using RTableTools
using ProgressMeter

using DiskArrayTools: diskstack, DiskArrayTools
# using Pkg; Pkg.activate(".")


dir_root = "z:/MODIS/Terra_LAI_v061_nc/"
files = dir(dir_root, ".nc\$")

dateInfo = fread("data/MODIS_LAI_dateInfo.csv")

years = @pipe basename.(files) |> str_extract("\\d{4}") |> parse.(Int, _)
chunks = @pipe basename.(files) |> str_extract(r"(?<=_)\d_\d")

info = DataFrame(; year=years, chunk=chunks, file=files)
all_chunks = unique(chunks)

# 计算lambda的分组
info_group = DataFrame(;
  year_min=[2000, 2005, 2010, 2015, 2018],
  year_max=[2004, 2009, 2014, 2019, 2022]
)

# k = 5 (1-5)
k = 5
year_min, year_max = info_group[k, [:year_min, :year_max]]
_dateInfo = @pipe dateInfo |> _[(year_min.<=_.year.<=year_max), :]
dates = _dateInfo.date




chunk = "2_4"
d = @pipe info |> _[(year_min.<=_.year.<=year_max).&&(_.chunk.==chunk), :]

fs = d.file

## 设计一个全球计算框架

using YAXArrays


m = MFDataset(fs)
# ncs = nc_open.(m.fs)

nc = NCDataset(d.file)
nc = nc_open(d.file)

ds = open_dataset.(d.file)

cube = concatenatecubes(ds, Dim{:time})

diskstack()
# include("main_nc.jl")
# include("main_stars.jl")
# include("main_whit.jl")
