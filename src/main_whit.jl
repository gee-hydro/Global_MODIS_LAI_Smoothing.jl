using Whittaker2
using Statistics

"""
`method`: `cv` or `lambda`
"""
function pixel_cal_lambda(y, qc; wmin::Float32=0.2f0, method = "cv", w=nothing, interm=nothing, ignore...)
  # @show y, qc, ignore
  missval = UInt8(255)
  y[y.==missval] .= UInt8(0)
  qc[qc.==missval] .= UInt8(0)

  if (std(y) < 0.1)
    return zeros(Float32, 4)
  end

  # https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom
  # 多进程时`w`, `intern`与可能会导致错误
  n = length(y)
  w === nothing && (w = zeros(Float32, n))
  interm === nothing && (interm = interm_whit{Float32}(; n))

  inds_miss = ((y .== UInt8(0)) .&& (qc .== UInt8(0)))
  # https://code.earthengine.google.com/27030439513c0bce3ac0d9d62079b827
  # qc与y同时为0的比例，极低
  qc_FparLai!(w, qc; include_flag=false)
  w[inds_miss] .= wmin
  
  if method == "cv"
    lambda = lambda_cv(y, w; interm)
  elseif method == "lambda"
    lambda = lambda_lambda(y, w; interm)
  end
  
  ylu, wc = get_ylu(y, w)
  lambda, ylu..., wc
end


function process_whit_chunk(d; outdir="OUTPUT", overwrite=false)
  year_min = minimum(d.year)
  year_max = maximum(d.year)
  fout = "$outdir/$year_min-$(year_max)_grid,$(d.chunk[1]).tif"

  (isfile(fout) && !overwrite) && return

  chunkszie = (240 * 30, 240 * 30, typemax(Int))
  m = MFDataset(d.fs, chunkszie)

  n = m.ntime
  w = zeros(Float32, n)
  interm = interm_whit{Float32}(; n)
  res = mapslices_3d(pixel_cal_lambda, m; n_run=1, method="cv", w, interm)

  b = nc_st_bbox(m.fs[1])
  x, y = Terra.guess_dims(res, b)[1:2]
  dim_band = Rasters.Band(["lambda", "ymin", "ymax", "wc"])
  r = rast(res, (x, y, dim_band))
  @time st_write(r, fout)
end
