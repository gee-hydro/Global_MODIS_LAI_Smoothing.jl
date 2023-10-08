## 测试进程占用的问题

## 这里提前把任务划分好
Threads.@threads for i = 1:10
 	@show Threads.threadid()
end


## 保存成Zarr
# ds = YAXArray((x, y, dim_band), res)
# @time savecube(ds, "OUTPUT/temp-01.zarr")

# using Plots
# heatmap(r[:, :, 1])
# @time r1 = mapslices_3d(mean, A; parallel=true);
# r2 = mapslices_3d(mean, A; parallel=false)
# add(x, y) = x + y
## 测试保存数据的方法