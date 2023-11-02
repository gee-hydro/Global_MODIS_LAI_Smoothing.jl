#! julia -t 12 s1_param_lambda.jl
println(Threads.nthreads())

using Revise
includet("../src/MODISTools.jl")


function nanmaximum(x::AbstractVector{T}) where {T}
  x[x.==T(255)] .= T(0)
  maximum(x)
end

function process_LAI(d; outdir="OUTPUT", overwrite=false, prefix="LAI_max_")
  year_min = minimum(d.year)
  year_max = maximum(d.year)
  fout = "$outdir/$(prefix)$year_min-$(year_max)_grid,$(d.grid[1]).tif"

  (isfile(fout) && !overwrite) && return
  @show fout

  chunkszie = (240 * 30, 240 * 30, typemax(Int))
  m = MFDataset(d.file[1:1], chunkszie)

  InVars = m.bands[1:1]
  res = mapslices_3d(nanmaximum, m, InVars; n_run=nothing)

  b = nc_st_bbox(m.fs[1])
  x, y = Terra.guess_dims(res, b)[1:2]
  dim_band = Rasters.Band(["mean"])
  r = rast(res, (x, y, dim_band))
  @time st_write(r, fout)
end

# for k = reverse(1:5)
k = 5;
grid = "2_4"

for k = reverse(1:5)
  year_min, year_max = info_group[k, [:year_min, :year_max]]

  for grid in reverse(all_grids)
    d = @pipe info |> _[(year_min.<=_.year.<=year_max).&&(_.grid.==grid), :]
    process_LAI(d)
  end
end



# _dateInfo = @pipe dateInfo |> _[(year_min.<=_.year.<=year_max), :]
# dates = _dateInfo.date

# for grid in reverse(all_grids)
# d = @pipe info |> _[(year_min.<=_.year.<=year_max).&&(_.grid.==grid), :]
# end
# end
