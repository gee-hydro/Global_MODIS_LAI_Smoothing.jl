#! julia -t 16 s1_param_lambda.jl
println(Threads.nthreads())

using Revise
includet("src/MODISTools.jl")


function process_whit_chunk(d; outdir="OUTPUT", overwrite=false, method="cv")
  year_min = minimum(d.year)
  year_max = maximum(d.year)
  fout = "$outdir/lambda_$(method)_$year_min-$(year_max)_grid,$(d.grid[1]).tif"

  (isfile(fout) && !overwrite) && return
  @show fout

  chunkszie = (240 * 30, 240 * 30, typemax(Int))
  m = MFDataset(d.file, chunkszie)

  n = m.ntime
  w = zeros(Float32, n)
  interm = interm_whit{Float32}(; n)
  res = mapslices_3d(pixel_cal_lambda, m; n_run=nothing, method, w, interm, option=2)

  b = nc_st_bbox(m.fs[1])
  x, y = Terra.guess_dims(res, b)[1:2]
  dim_band = Rasters.Band(["lambda", "ymin", "ymax", "wc"])
  r = rast(res, (x, y, dim_band))
  @time st_write(r, fout)
end

# _dateInfo = @pipe dateInfo |> _[(year_min.<=_.year.<=year_max), :]
# dates = _dateInfo.date

# k = 5
for k = reverse(1:5)
  year_min, year_max = info_group[k, [:year_min, :year_max]]
  for grid in all_grids
    d = @pipe info |> _[(year_min.<=_.year.<=year_max).&&(_.grid.==grid), :]
    process_whit_chunk(d)
  end
end
