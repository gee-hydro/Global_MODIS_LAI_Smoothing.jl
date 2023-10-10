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
b = Terra.bbox(-180, -60, 180, 90)
lon, lat = bbox2dims(b; cellsize=1 / 12)
band = Band(["lambda", "ymin", "ymax", "wc"])
chunk_size = (240 * 10, 240 * 10, length(band))

p = "OUTPUT/temp-03.zarr/"
z = geo_zcreate(p, "lambda_cv", lon, lat, band; chunk_size)
z = nothing
zarr_rm(p)
# z2 = open_dataset(p)

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
