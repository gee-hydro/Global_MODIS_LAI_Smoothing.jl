Bslice(i, j) = ()
Bslice(B::AbstractArray{T,3}, i, j) where {T} = @view(B[i, j, :])
Bslice(B::Tuple, i, j) where {T} = map(b -> @views(b[i, j, :]), B)

test_Bslice(B...;) = Bslice(B, 1, 1)
# x = rand(2, 2, 2)
# test_Bslice()
# test_Bslice(x)
# test_Bslice(x, x, x)

# 仅针对3维数据设计的一个并行算法
## 这个算法移植到YAXArrays，能否变快
function mapslices_3d(f, A::AbstractArray, B...; parallel=true, progress=nothing, kw...)
  nlon, nlat = size(A)[1:2]
  
  r = f(A[1, 1, :], Bslice(B, 1, 1)...; kw...)
  res = zeros(eltype(r), nlon, nlat, length(r))

  progress === nothing && (progress = Progress(nlon*nlat))
  @par parallel for i = 1:nlon
    for j = 1:nlat
      next!(progress)

      x = @view(A[i, j, :])
      y = Bslice(B, i, j)
      res[i, j, :] .= f(x, y...; kw...)
    end
  end
  res
end


function mapslices_3d(f, m::MFDataset, InVars=m.bands; kw...)
  _data = map(band -> m[band][1:1, 1:1], InVars) # this is a list of data
  r = mapslices_3d(f, _data...; kw...)

  nlon, nlat = m.sizes[1][1:2]
  res = zeros(eltype(r), nlon, nlat, length(r))
  obj_size(res)
  
  mapslices_3d!(res, f, m, InVars; kw...)
end


function mapslices_3d!(res, f, m::MFDataset, InVars=m.bands; parallel=true, progress=nothing, kw...)
  nlon, nlat = m.sizes[1][1:2]
  progress = Progress(nlon*nlat)
  ## 算完然后再切另一块数据
  for _chunk in m.chunks
    ii, jj, _ = _chunk
    printstyled("[chunk=$k]reading data ...\n", color = :blue, bold=true)
    l_data = map(band -> m[band][ii, jj], InVars) # this is a list of data
    res[ii, jj, :] .= mapslices_3d(f, l_data...; kw..., progress)
  end
end
