"""
- `n_run`: run how many chunks, default all
"""
function mapslices_3d!(res::Array, 
  f::Function, m::MFDataset, InVars=m.bands; n_run=nothing, parallel=true, kw...)

  # nlon, nlat = m.sizes[1][1:2]
  # n = length(m.chunks)
  n_run === nothing && (n_run = length(m.chunks))
  # progress = Progress(length(ii) * length(jj))

  ## 算完然后再切另一块数据
  for k in 1:n_run
    printstyled("[chunk=$k] reading data ...\n", color=:blue, bold=true)
    ii, jj, _ = m.chunks[k]
    @time l_data = map(band -> m[band][ii, jj], InVars) # this is a list of data

    println("[chunk=$k] calculating ...")
    @time res[ii, jj, :] .= mapslices_3d_chunk(f, l_data...; kw..., parallel)
  end
  res
end

function mapslices_3d(f::Function, m::MFDataset, InVars=m.bands; n_run=nothing, kw...)
  _data = map(band -> m[band][1:1, 1:1], InVars) # this is a list of data
  r = mapslices_3d_chunk(f, _data...; kw...)

  nlon, nlat = m.sizes[1][1:2]
  res = zeros(eltype(r), nlon, nlat, length(r))
  obj_size(res)

  mapslices_3d!(res, f, m, InVars; n_run, kw...)
end
