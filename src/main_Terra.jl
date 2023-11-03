using ArchGDAL
using Shapefile
using Terra
using YAXArrays
using Zarr
using Zarr: ConcurrentRead
Zarr.store_read_strategy(::DirectoryStore) = ConcurrentRead(Zarr.concurrent_io_tasks[])

## 判断哪个grid被选择了
function which_grid(ds, (lon, lat))
  zs = get_zarr(ds)
  bs = st_bbox.(zs)
  inds = in_bbox(bs, (lon, lat)) |> findall
  !isempty(inds) ? names(ds)[inds[1]] : nothing
end


function st_ds2tiff(ds::YAXArrays.Dataset; 
  prefix = "lambda_cv_2018-2022", outdir="OUTPUT/GEE", overwrite=false)
  
  @par for grid in names(ds)
    grid2 = gsub(grid, "grid.", "grid")
    fout = "$outdir/$(prefix)_$grid2.tif"

    z = ds[grid].data
    b = st_bbox(z)
    # lims = ((b.xmin, b.xmax), (b.ymin, b.ymax))
    λ = @view z[:, :, 1] # 只保存lambda
    ra = Raster(λ, b; missingval=0.0f0, crs=EPSG(4326))

    if !isfile(fout) || overwrite
      @show fout
      # GEE不支持默认的数据压缩方式
      # options=Dict("COMPRESS"=>"LZW")
      @time write(fout, ra;
        options=Dict("COMPRESS" => "DEFLATE"),
        force=true)
    end
  end
end
