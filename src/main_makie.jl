using GLMakie
using Colors
using DimensionalData
using JLD2
using Statistics
using Printf
# using NaNStatistics
# includet("MFDataset.jl")

nan_color = RGBA(1.0, 1.0, 1.0, 0.2)

## functions for makie 
function my_theme!(; font_size=24)
  kw_axes = (xticklabelsize=font_size, yticklabelsize=font_size,
    xlabelsize=font_size, ylabelsize=font_size,
    xlabelfont=:bold, ylabelfont=:bold)
  mytheme = Theme(fontsize=30, Axis=kw_axes)
  set_theme!(mytheme)
end

function terra_heatmap!(ax, r::Raster; missingval=nothing, kw...)
  missingval === nothing && (missingval = r.missingval)

  x, y = st_dims(r)
  z = r.data
  T = eltype(r)

  z[z.==T(missingval)] .= T(NaN)
  heatmap!(ax, x, y, z; kw...)
end

function sbig_heatmap!(ax, x, y, z; fact=10, kw...)
  x2 = x[1:fact:end]
  y2 = y[1:fact:end]
  z2 = @lift $z[1:fact:end, 1:fact:end]

  handle = heatmap!(ax, x2, y2, z2, kw...)
  handle
end

function big_heatmap!(ax, x, y, z; fact=10, kw...)
  x2 = x[1:fact:end]
  y2 = y[1:fact:end]
  z2 = z[1:fact:end, 1:fact:end]

  handle = heatmap!(ax, x2, y2, z2; kw...)
  handle
end

"""
- `fun!`: 只接受两个参数，其他需要放在`kw...`。
"""
function map_on_mouse(ax, handle_plot, slon, slat;
  verbose=false, (fun!)=nothing, kw...)

  on(events(fig).mousebutton, priority=2) do event
    if event.button == Mouse.left && event.action == Mouse.press
      # plt, i = pick(ax)
      pos = mouseposition(ax)
      # 如果不在axis范围内
      if ax.limits[] !== nothing
        xlim, ylim = ax.limits[]
        if !((xlim[1] <= pos[1] <= xlim[2]) && (ylim[1] <= pos[2] <= ylim[2]))
          return Consume(false)
        end
      end
      slon[] = pos[1]
      slat[] = pos[2]
      verbose && @show slon[], slat[]
      if (fun!) !== nothing
        fun!(slon[], slat[]; kw...)
      end
    end
    return Consume(false)
  end
end

function map_on_keyboard(fig, slon, slat, stime, cellx, celly; step=10)
  on(events(fig).keyboardbutton) do event
    if event.action == Keyboard.press || event.action == Keyboard.repeat
      if event.key == Keyboard.up
        slat[] += celly * step
      elseif event.key == Keyboard.down
        slat[] -= celly * step
      elseif event.key == Keyboard.right
        slon[] += cellx * step
      elseif event.key == Keyboard.left
        slon[] -= cellx * step
      elseif event.key == Keyboard.page_up
        stime[] += 1
      elseif event.key == Keyboard.page_down
        stime[] -= 1
      end
    end
    return Consume(false)
  end
end

## load data -------------------------------------------------------------------
# arr = load("temp.jld2", "arr_Tmax");
# nlon, nlat, ntime = size(arr)
# vol = replace(arr, missing => NaN32) .- 273.15;
# size(vol)

# x = 1:nlon
# y = 1:nlat
# z = 1:ntime

# cellsize = 0.5
# lon = 70+cellsize/2:cellsize:140
# lat = 15+cellsize/2:cellsize:55
# time = 1:366

## plot for shapefile
using Shapefile

# https://discourse.julialang.org/t/best-way-of-handling-shapefiles-in-makie/71028/9
function Makie.convert_arguments(::Type{<:Poly}, p::Shapefile.Polygon)
  # this is inefficient because it creates an array for each point
  polys = Shapefile.GeoInterface.coordinates(p)
  ps = map(polys) do pol
    Polygon(
      Point2f0.(pol[1]), # interior
      map(x -> Point2f.(x), pol[2:end]))
  end
  (ps,)
end

function plot_poly!(ax, shp;
  color=nan_color, strokewidth=0.7, strokecolor=:black, kw...)

  foreach(shp.geometry) do geo
    poly!(ax, geo; color, strokewidth, strokecolor, kw...)
  end
end

bbox2rect(b) = Rect(b.xmin, b.ymin, b.xmax - b.xmin, b.ymax - b.ymin)
