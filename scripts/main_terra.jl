# using Stars
# using Stars: bbox
using Terra
using NetCDFTools
using NCDatasets
using ProgressMeter

# function vec_split(list, names)
#   grps = unique(names)
#   map(grp -> Pair(grp, list[names.==grp]), grps)
# end

# function Stars.readGDAL(files::Vector{<:AbstractString}, args...; verbose=true, kw...)
#   # bands = collect(bands)
#   # bands = collect(Int32, bands)
#   res = map(file -> begin
#       verbose && println("running: $(basename(file)) ")
#       readGDAL(file, args...; kw...)
#     end, files)
#   res
# end

function nc_st_bbox(file)
  nc_open(file) do nc
    lat = nc[r"lat"][:]
    lon = nc[r"lon"][:]
    st_bbox(lon, lat)
  end
end

##------------------------------------------------------------------------------

# only works for 3d var
function nc_mosaic(fs, band="LAI"; ind=nothing)
  bs = nc_st_bbox.(fs)
  box = st_bbox(bs)

  lon, lat = bbox2dims(box)
  A = zeros(UInt8, length(lon), length(lat), 1)
  r = rast(A, box)

  # if ind === nothing
  #   ntime = nc_date(fs[1]) |> length
  #   ind = (:, :, ntime)
  # end
  @showprogress for f in fs
    b = nc_st_bbox(f)
    data = nc_read(f, band; ind)
    ilon, ilat = bbox_overlap(b, box)
    r.A[ilon, ilat, :] .= data
  end
  r
end

# Variable 'LAI' not found in file z:/MODIS/Terra_LAI_v061_nc/MOD15A2H_v061-raw2-LAI_240deg_global_2014_1_0.nc
function merge_first_img(info, years, band="LAI")
  for _year in years
    fout = "data/$(band)_$(_year)_26.tif"
    # if isfile(fout)
    #   continue
    # end
    d = @pipe info |> _[_.year.==_year, :]
    fs = d.file

    @show fout
    try
      r = nc_mosaic(fs, band; ind=(:, :, 26))
      st_write(r, fout)
    catch ex
      @show fout, ex
    end
  end
end
