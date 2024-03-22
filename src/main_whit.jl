using ArchGDAL
using Shapefile
using Terra
using YAXArrays
using Zarr
# using Zarr: ConcurrentRead
# Zarr.store_read_strategy(::DirectoryStore) = ConcurrentRead(Zarr.concurrent_io_tasks[])
using Whittaker2
using Statistics

"""
`method`: `cv` or `lambda`
"""
function pixel_cal_lambda(y, qc; 
  w::Union{Nothing,Vector{Float32}}=nothing,
  interm::Union{Nothing,interm_whit{Float32}}=nothing,
  kw...)

  n = length(y)
  w === nothing && (w = zeros(Float32, n))
  interm === nothing && (interm = interm_whit{Float32}(; n))

  whit_calib_lambda(y, qc, w, interm; kw...)
end

lambda_fun = Dict("cv" => lambda_cv, "vcurve" => lambda_vcurve)

function whit_calib_lambda(y::AbstractVector{T}, qc::AbstractVector{T}, w::AbstractVector{Float32}, interm::interm_whit{Float32};
  wmin::Float32=0.2f0, method="cv", ignore...) where {T<:Integer}
  
  missval = UInt8(255)
  replace!(y, missval => UInt8(0))
  replace!(qc, missval => UInt8(0))

  if (std(y) < 0.1)
    return zeros(Float32, 4)
  end

  # https://code.earthengine.google.com/27030439513c0bce3ac0d9d62079b827
  # qc与y同时为0的比例，极低
  qc_FparLai!(w, qc; include_flag=false)
  inds_miss = ((y .== UInt8(0)) .&& (qc .== UInt8(0)))
  w[inds_miss] .= wmin

  fun = lambda_fun[method]
  lambda = fun(y, w; interm)

  ylu, wc = get_ylu(y, w)
  lambda, ylu..., wc
end
