using JLD2

"""
- `n_run`: run how many chunks, default all
"""
function mapslices_3d!(z::ZArray,
  f::Function, m::MFDataset, InVars=m.bands; n_run=nothing, parallel=false, kw...)

  nlon, nlat = m.sizes[1][1:2]
  progress = Progress(nlon * nlat)

  # n = length(m.chunks)
  n_run === nothing && (n_run = length(m.chunks))

  ## 算完然后再切另一块数据
  for k in 1:n_run
    if chunk_task_finished(z, k)
      continue
    end

    _chunk = m.chunks[k]
    ii, jj, _ = _chunk

    printstyled("\t[chunk=$k] reading data ...\n", color=:blue, bold=true)
    @time l_data = map(band -> m[band][ii, jj], InVars) # this is a list of data

    println("\t[chunk=$k] calculating ...")
    # jldsave("debug.jld2"; l_data, kw)
    
    try
      r = mapslices_3d_chunk(f, l_data...; kw..., parallel, progress)
      z[ii, jj, :] .= r
    catch ex
      @show "chunk=$k", ex
    end
    chunk_task_finished!(z, k) # 运行成功的chunk进行标记
  end
  z
end

## only for LAI smoothing 
"""
- `p`: the path of zarr
"""
function mapslices_3d_zarr(p::String,
  f::Function, m::MFDataset, InVars=m.bands; n_run=nothing, overwrite=false, kw...)
  # _data = map(band -> m[band][1:1, 1:1], InVars) # this is a list of data
  # r = mapslices_3d_chunk(f, _data...; kw...)
  
  # res = zeros(eltype(r), nlon, nlat, length(r))
  # r = mapslices_3d_chunk(f, _data...; kw...)
  # nlon, nlat = m.sizes[1][1:2]
  # res = zeros(eltype(r), nlon, nlat, length(r))
  # obj_size(res)

  ## 上大招
  cellsize = 1 / 240
  band = Band(["lambda", "ymin", "ymax", "wc"])
  chunk_size = m.chunksize

  if !isdir(p) || overwrite
    (isdir(p) && overwrite) && zarr_rm(p)
    z = geo_zcreate(dirname(p), basename(p), m.bbox, cellsize, band; chunk_size)  
  else
    z = zopen(z)
  end    
  println(z)
  mapslices_3d!(z, f, m, InVars; n_run, kw...)
end