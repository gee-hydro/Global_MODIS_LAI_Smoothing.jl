TupleSlice(i, j) = ()
@inbounds TupleSlice(B::AbstractArray{T,3}, i, j) where {T} = @view(B[i, j, :])
@inbounds TupleSlice(B::Tuple, i, j) = map(b -> @view(b[i, j, :]), B)

# test_TupleSlice(B...;) = TupleSlice(B, 1, 1)
# x = rand(2, 2, 2)
# test_TupleSlice()
# test_TupleSlice(x)
# test_TupleSlice(x, x, x)

# 仅针对3维数据设计的一个并行算法
# TODO: 这个算法移植到YAXArrays，能否变快
function mapslices_3d_chunk(f::Function, A::AbstractArray, B...;
  parallel=true,
  option=2,
  progress=nothing, kw...)

  r = f(A[1, 1, :], TupleSlice(B, 1, 1)...; kw...)
  nlon, nlat = size(A)[1:2]
  res = zeros(eltype(r), nlon, nlat, length(r))

  function subfun(I; kw...)
    next!(progress)
    i, j = I

    @inbounds begin
      x = @view A[i, j, :]
      y = TupleSlice(B, i, j)
      try
        res[i, j, :] .= f(x, y...; kw...)
      catch ex
        @show "[e] i=$i, j=$j" ex
        throw(ex)
      end
    end
  end

  ## https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom
  ## https://docs.julialang.org/en/v1/manual/multi-threading/#Using-@threads-without-data-races
  # 为了节省内存，把程序改的很复杂，实属无奈
  progress === nothing && (progress = Progress(nlon * nlat))
  nworker = Threads.nthreads()

  inds = collect(Iterators.product(1:nlon, 1:nlat))[:]
  kws = [deepcopy(kw) for _ in 1:nworker]

  if option == 1
    # 方案1：划分成块
    i_chunks = r_chunk(inds, nworker)
    @par parallel for t = 1:nworker
      kw = kws[t]
      for I in i_chunks[t]
        subfun(I; kw...)
      end
    end
  elseif option == 2
    # 方案2：指定下标
    @par parallel for I in inds
      t = Threads.threadid()
      kw = kws[t]
      subfun(I; kw...)
    end
  end
  res
end

## with_kw
# option1: 
# > 457.822881 seconds (132.33 M allocations: 10.441 GiB, 0.45% gc time, 7.23% compilation time)

# option2:
# > 62.827463 seconds (206.90 M allocations: 14.488 GiB, 4.12% gc time, 2.68% compilation time)
# > 性能提升了25%

# 为何他们俩性能相差这么多？
