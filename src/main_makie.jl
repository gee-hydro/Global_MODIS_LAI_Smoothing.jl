using GLMakie
using DimensionalData
using JLD2
using Statistics
using Printf
# using NaNStatistics
includet("MFDataset.jl")


function findnear(values, x)
  _, i = findmin(abs.(values .- x))
  values[i], i
end

function my_theme!(; font_size=24)
  kw_axes = (xticklabelsize=font_size, yticklabelsize=font_size,
    xlabelsize=font_size, ylabelsize=font_size,
    xlabelfont=:bold, ylabelfont=:bold)
  mytheme = Theme(fontsize=30, Axis=kw_axes)
  set_theme!(mytheme)
end

function big_heatmap!(ax, x, y, z; fact=10)
  x2 = x[1:fact:end]
  y2 = y[1:fact:end]
  z2 = @lift $z[1:fact:end, 1:fact:end]

  handle = heatmap!(ax, x2, y2, z2)
  handle
end

function map_on_mouse(fig, handle_plot, slon, slat)
  on(events(fig).mousebutton, priority=2) do event
    if event.button == Mouse.left && event.action == Mouse.press
      plt, i = pick(fig)
      if plt == handle_plot
        pos = mouseposition(ax_xy)
        slon[] = pos[1]
        slat[] = pos[2]
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
