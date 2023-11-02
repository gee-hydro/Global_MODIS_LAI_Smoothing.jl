"""
- `chunks`: which chunks to run, default all.
"""
function mapslices_3d!(z::ZArray,
  f::Function, m::MFDataset, InVars=m.bands; 
  chunks=nothing, parallel=true, overwrite=false, kw...)

  # nlon, nlat = m.sizes[1][1:2]
  # progress = Progress(nlon * nlat)
  chunks === nothing && (chunks = 1:length(m.chunks))

  for k in chunks
    (chunk_task_finished(z, k) && !overwrite) && continue
    
    printstyled("\t[chunk=$k] reading data ...\n", color=:blue, bold=true)
    ii, jj, _ = m.chunks[k]
    @time l_data = get_chunk(m, k; InVars) # list of input data

    println("\t[chunk=$k] calculating ...")
    # jldsave("debug.jld2"; l_data, kw)
    try
      @time r = mapslices_3d_chunk(f, l_data...; kw..., parallel)
      z[ii, jj, :] .= r
      chunk_task_finished!(z, k) # 运行成功的chunk进行标记
    catch ex
      @show "chunk=$k", ex
    end
  end
  z
end

## only for LAI smoothing 
"""
- `p`: the path of zarr
"""
function mapslices_3d_zarr(p::String,
  f::Function, m::MFDataset, InVars=m.bands; overwrite=false, kw...)
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
    z = zopen(p, "w")
  end
  println(z)
  mapslices_3d!(z, f, m, InVars; kw...)
end
