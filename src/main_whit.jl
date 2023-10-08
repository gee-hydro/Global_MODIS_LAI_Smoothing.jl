using Whittaker2

"""
`method`: `cv` or `lambda`
"""
function pixel_cal_lambda(y, qc; wmin::Float32=0.2f0, method = "cv", w=nothing, interm=nothing)
  missval = UInt8(255)
  y[y.==missval] = UInt8(0)
  qc[qc.==missval] = UInt8(0)

  if (std(y) < 0.1)
    return
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

# #! deprecated
# function cal_lambda(LAI, QC; kw...)
#   nrow, ncol = size(LAI)[1:2]
#   res = zeros(Float32, nrow, ncol, 4) # lambda, ylu and wc
  
#   n = size(LAI, 3)
#   w = zeros(Float32, n)
#   interm = interm_whit{Float32}(; n)

#   @time @showprogress for i = 1:nrow, j = 1:ncol
#     @views y = LAI[i, j, :]
#     @views qc = QC[i, j, :]

#     res[i, j, ...] .= pixel_cal_lambda(y, qc; w, interm, kw...)
#   end
#   res
# end
