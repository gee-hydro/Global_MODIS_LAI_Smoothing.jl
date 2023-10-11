using Revise
includet("../src/MODISTools.jl")

# dims = (X(lon), Y(lat), band)
# A = zeros(Float32, dims);
# ds = YAXArray(dims, A.data;)
# ds = setchunks(ds, chunks)
# ds = YAXArray(dims)
# f = "OUTPUT/temp-02.zarr/"
# savecube(ds, f)
# z = Cube(f)

## 创建zarr --------------------------------------------------------------------
b = Terra.bbox(30, 60, 180, 90)
cellsize = 1 / 240
# lon, lat = bbox2dims(b; cellsize=1 / 12)
band = Band(["lambda", "ymin", "ymax", "wc"])
chunk_size = (240 * 10, 240 * 10, length(band))

p = "OUTPUT/global_param_lambda_cv-02"
isdir(p) && zarr_rm(p)
z = geo_zcreate(p, "grid.2-3", b, cellsize, band; chunk_size)
z2 = geo_zcreate(p, "grid.2-4", b, cellsize, band; chunk_size)
# z = nothing
# z2 = Cube(p)
# Cube(p)
open_dataset(p; driver=:zarr)

## 测试任务模块
dict = z.attrs
task_finished!(z, 1)

## 保存成Zarr
# ds = YAXArray((x, y, dim_band), res)
# @time savecube(ds, "OUTPUT/temp-01.zarr")

# using Plots
# heatmap(r[:, :, 1])
# @time r1 = mapslices_3d(mean, A; parallel=true);
# r2 = mapslices_3d(mean, A; parallel=false)
# add(x, y) = x + y


cellsize = 1 / 240
band = Band(["lambda", "ymin", "ymax", "wc"])
chunk_size = m.chunksize
overwrite && zarr_rm(p)

z = geo_zcreate(dirname(p), basename(p), m.bbox, cellsize, band; chunk_size)
println(z)

temp = rand(Float32, 1200, 1200, 4);
z[1:1200, 1:1200, :] .= temp



p = "Z:/GitHub/jl-spatial/Whittaker2.jl/scripts/Project_Global_LAI_smoothing/OUTPUT/global_param_lambda_cv_2018-2022.zarr/grid.0_0"
z = geo_zcreate(dirname(p), basename(p), m.bbox, cellsize, band; chunk_size=m.chunksize)

z[1:1200, 1:1200, :] .= temp
