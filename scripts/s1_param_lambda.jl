#! julia -t 15 s1_param_lambda.jl
println(Threads.nthreads())

using Ipaper
using Revise
includet("../src/MODISTools.jl")

method = "cv"
method = "vcurve"
overwrite = false

function process_whit_chunk(d;)
  year_min = minimum(d.year)
  year_max = maximum(d.year)

  grid = d.grid[1]
  prefix = "lambda_$method"
  outdir = "./OUTPUT/global_param_$prefix/$(prefix)_$year_min-$(year_max).zarr"
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

# 2017年少了一年, `2017-11-25` missing
2000: (28800, 7200, 40)
2001: (28800, 7200, 44)
2002: (28800, 7200, 46)
2003: (28800, 7200, 46)
2004: (28800, 7200, 46)
2005: (28800, 7200, 46)
2006: (28800, 7200, 46)
2007: (28800, 7200, 46)
2008: (28800, 7200, 46)
2009: (28800, 7200, 46)
2010: (28800, 7200, 46)
2011: (28800, 7200, 46)
2012: (28800, 7200, 46)
2013: (28800, 7200, 46)
2014: (28800, 7200, 46)
2015: (28800, 7200, 46)
2016: (28800, 7200, 45)
2017: (28800, 7200, 45)
2018: (28800, 7200, 46)
2019: (28800, 7200, 46)
2020: (28800, 7200, 46)
2021: (28800, 7200, 46)
2022: (28800, 7200, 45)
