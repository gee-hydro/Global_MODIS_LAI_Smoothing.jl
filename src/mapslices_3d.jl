Bslice(i, j) = ()
Bslice(B::AbstractArray{T,3}, i, j) where {T} = @view(B[i, j, :])
Bslice(B::Tuple, i, j) = map(b -> @views(b[i, j, :]), B)

test_Bslice(B...;) = Bslice(B, 1, 1)
# x = rand(2, 2, 2)
# test_Bslice()
# test_Bslice(x)
# test_Bslice(x, x, x)

# 仅针对3维数据设计的一个并行算法
# TODO: 这个算法移植到YAXArrays，能否变快
function mapslices_3d(f, A::AbstractArray, B...; 
  parallel=true, option = 1, 
  progress=nothing, kw...)

  nlon, nlat = size(A)[1:2]
  
  r = f(A[1, 1, :], Bslice(B, 1, 1)...; kw...)
  res = zeros(eltype(r), nlon, nlat, length(r))

  function subfun(I; kw...)
    next!(progress)
    i, j = I
    x = @view(A[i, j, :])
    y = Bslice(B, i, j)
    res[i, j, :] .= f(x, y...; kw...)
  end

  ## https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom
  ## https://docs.julialang.org/en/v1/manual/multi-threading/#Using-@threads-without-data-races
  # 为避免数据争夺，想办法对kw进行拷贝，提前划分好chunks
  # 为了节省内存，把程序改的很复杂，实属无奈
  nworker = Threads.nthreads()
  progress === nothing && (progress = Progress(nlon*nlat))

  if option == 1
    ## 并行: 方案1
    inds = collect(Iterators.product(1:nlon, 1:nlat))[:]
    i_chunks = r_chunk(inds, nworker)
    kws = repeat([kw], nworker)
    # nt = min(nworker, length(i_chunks))
    @par parallel for t = 1:nworker
      kw = kws[t]
      for I in i_chunks[t]
        subfun(I; kw)
      end
    end
  elseif option == 2
    ## 并行: 方案2
    @par parallel for I in inds
      t = Threads.threadid()
      kw = kws[t]
      subfun(I; kw)
    end
  end
  res
end


"""
- `n_run`: run how many chunks, default all
"""
function mapslices_3d!(res, f, m::MFDataset, InVars=m.bands; n_run=nothing, parallel=true, progress=nothing, kw...)
  nlon, nlat = m.sizes[1][1:2]
  progress = Progress(nlon*nlat)

  n = length(m.chunks)
  n_run === nothing && (n_run = length(m.chunks))

  ## 算完然后再切另一块数据
  for k in 1:n_run
    # 把kw...每个拷贝一份?
    _chunk = m.chunks[k]
    ii, jj, _ = _chunk
    printstyled("[chunk=$k] reading data ...\n", color = :blue, bold=true)
    @time l_data = map(band -> m[band][ii, jj], InVars) # this is a list of data

    println("[chunk=$k] calculating ...")
    @time res[ii, jj, :] .= mapslices_3d(f, l_data...; kw..., progress)
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
