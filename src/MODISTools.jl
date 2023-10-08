# module MODISTools

includet("MFDataset.jl")
includet("mapslices_3d.jl")
includet("main_whit.jl")
includet("zarr.jl")


using Terra
function nc_st_bbox(file)
  nc_open(file) do nc
    lat = nc[r"lat"][:]
    lon = nc[r"lon"][:]
    st_bbox(lon, lat)
  end
end
# end
