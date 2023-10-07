using Whittaker2
using ProgressMeter


# @everywhere 
function cal_lambda(LAI, QC; wmin::Float32=0.2f0)
  nrow, ncol = size(LAI)[1:2]
  lambda = zeros(nrow, ncol)
  ylu = zeros(nrow, ncol, 2)
  w_critical = zeros(nrow, ncol)

  n = size(LAI, 3)
  w = zeros(Float32, n)

  interm = interm_whit{Float32}(; n)
  @time @showprogress for i = 1:nrow, j = 1:ncol
    @views y = LAI[i, j, :]
    @views qc = QC[i, j, :]

    # 跳过全部为空的区域
    if (std(y) < 0.1)
      continue
    end

    # 警惕missing vals
    inds_miss = ((y .== UInt8(0)) .&& (qc .== UInt8(0)))
    # https://code.earthengine.google.com/27030439513c0bce3ac0d9d62079b827
    # qc与y同时为0的比例，极低
    # w, flag = qc_FparLai(qc)
    qc_FparLai!(w, qc; include_flag=false)
    w[inds_miss] .= wmin

    # d = DataFrame(; date = dates, y, qc, w, flag)
    # lambda[i, j] = lambda_vcurve(y, w; interm)
    lambda[i, j] = lambda_cv(y, w; interm)
    ylu[i, j, :], w_critical[i, j] = get_ylu(y, w)
  end
  # lambda, ylu, w_critical  
  abind(lambda, ylu, w_critical) # 四个变量存储在一起
end


function cal_chunk_lambda(d; outdir="OUTPUT", fact=4, overwrite=false)
  year_min = minimum(d.year)
  year_max = maximum(d.year)
  fs = d.file

  # box = nc_st_bbox(f)
  lon = nc_read(fs[1], "lon")
  lat = nc_read(fs[1], "lat")
  inds = split_grid(lon, lat; fact)

  # @distributed 
  for i in eachindex(inds)

    if !isCurrentWorker(i)
      continue
    end

    ind = (inds[i]..., :)

    str_chunk = @sprintf("%02d", i)
    fout = "$outdir/$year_min-$(year_max)_grid,$(d.chunk[1])_chunk,$str_chunk.tif"

    if isfile(fout) && !overwrite
      continue
    end

    printstyled("Reading data ...", bold=true, color=:green)
    @time data_LAI = pio_nc_read(fs, "LAI"; parallel="none", ind)
    data_QC = pio_nc_read(fs, "QcExtra"; parallel="none", ind)

    b = st_bbox(lon[ind[1]], lat[ind[2]])
    # r_LAI = rast(data_LAI, b)
    # r_QC = rast(data_QC, b)
    A = cal_lambda(data_LAI, data_QC)
    r = rast(A, b)
    st_write(r, fout)
  end
  nothing
end
