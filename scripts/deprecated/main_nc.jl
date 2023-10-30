import NCDatasets
using Ipaper: abind

# function Stars.st_bbox(nc::NCDatasets.NCDataset)
#   lat = nc[r"lat"][:]
#   lon = nc[r"lon"][:]
#   st_bbox(lon, lat)
# end

function resample_ncvar(nc, band=nothing; fact=2)
  band === nothing && (band = nc_bands(nc)[1])
  lat = nc[r"lat"][:]
  lon = nc[r"lon"][:]

  nlon = length(lon)
  nlat = length(lat)

  # 有提升空间，目前的版本会导致形成不规则的网格

  ## 经纬度的确定
  ilon = 1:fact:nlon
  ilat = 1:fact:nlat

  # var = nc[band]
  inds = (ilon, ilat, repeat([:], ndims(nc[band]) - 2)...)
  ## 还是用cdo处理更方便
  data = getindex(nc[band], inds...)

  dims = ncvar_dim(nc, band)
  dims[r"lon"] = dims[r"lon"][ilon]
  dims[r"lat"] = dims[r"lat"][ilat]
  dims, data
end


function nc_samplegrid(f, fout; fact=2, overwrite=false)
  nc = nc_open(f)
  bands = nc_bands(nc)
  band = bands[1]

  (isfile(fout) && !overwrite) && (return)

  for i = eachindex(bands)
    band = bands[i]
    var = nc[band]
    attrib = Dict(var.attrib)

    _dims, _data = resample_ncvar(nc, band; fact)
    if i == 1
      nc_write(fout, band, _data, _dims, attrib; global_attrib=Dict(nc.attrib))
    else
      nc_write!(fout, band, _data, _dims, attrib;)
    end
  end
  nc_close(nc)
  nothing
end


## 设计一个并行读取的算法
function split_grid(lon, lat; fact=5)
  nlon = length(lon)
  nlat = length(lat)

  inds_x = r_chunk(nlon, fact)
  inds_y = r_chunk(nlat, fact)
  # inds_x, inds_y
  # ngrid = length(inds_x) * length(inds_y)
  inds = []
  for indx = inds_x, indy = inds_y
    push!(inds, (indx, indy))
  end
  inds
end

function split_grid(nc; fact=5)
  lon = nc[r"lon"][:]
  lat = nc[r"lat"][:]
  split_grid(lon, lat; fact)
end


function pio_nc_read(fs, band; parallel="none", kw...)
  if parallel == "dist"
    # parallel
    res = @distributed (abind) for i = eachindex(fs)
      f = fs[i]
      @time nc_read(f, band; kw...)
    end
    res

  elseif parallel == "par"
    # par
    res = Vector{Any}(undef, length(fs))
    @par for i = eachindex(fs)
      f = fs[i]
      @time res[i] = nc_read(f, band; kw...)
    end
    Ipaper.abind(res...)

  else
    # serial
    res = @showprogress map(f -> nc_read(f, band; kw...), fs)
    abind(res...)
  end
end



## -----------------------------------------------------------------------------
## 并行读取: strategy





using DataFrames

function check_download(; years=2012:2021)
  dir_root = "H:/MODIS"
  lst_fs = map(year -> begin
      indir = "$dir_root/$year"
      fs = dir(indir)
    end, years)

  n = map(length, lst_fs)
  DataFrame(; year=years, n)
end
# check_download(; years=2012:2021)
