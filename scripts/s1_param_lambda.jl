#! julia -t 15 s1_param_lambda.jl
println(Threads.nthreads())

using Revise
includet("../src/MODISTools.jl")

method = "cv"
overwrite = false

function process_whit_chunk(d;)
  year_min = minimum(d.year)
  year_max = maximum(d.year)

  grid = d.grid[1]
  outdir = "OUTPUT/global_param_lambda_$(method)_$year_min-$(year_max).zarr"
  p = "$outdir/grid.$grid"
  
  println("\n=============================================")
  @show p
  chunkszie = (240 * 20, 240 * 10, typemax(Int)) 
  m = MFDataset(d.file, chunkszie)
  
  n = m.ntime
  w = zeros(Float32, n)
  interm = interm_whit{Float32}(; n)
  kw = (; w, interm)

  res = mapslices_3d_zarr(p, pixel_cal_lambda, m; chunks=nothing, method, kw...)
  GC.gc()
end

# _dateInfo = @pipe dateInfo |> _[(year_min.<=_.year.<=year_max), :]
# dates = _dateInfo.date

iters = collect(Iterators.product(all_grids, 1:4))
for i = eachindex(iters)
  I = iters[i]
  grid, k = I

  year_min, year_max = info_group[k, [:year_min, :year_max]]
  d = @pipe info |> _[(year_min.<=_.year.<=year_max).&&(_.grid.==grid), :]
  process_whit_chunk(d)
end

# @time LAI, QC = get_chunk(m, 18);
# @time r = mapslices_3d_chunk(pixel_cal_lambda, LAI, QC; option=2);
