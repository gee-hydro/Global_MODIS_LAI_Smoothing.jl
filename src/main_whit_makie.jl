using UnPack
using GLMakie
using PlotUtils: optimize_ticks
using Dates


function my_theme!(; font_size=24)
  kw_axes = (
    xticklabelsize=font_size, yticklabelsize=font_size,
    xlabelsize=font_size, ylabelsize=font_size,
    xlabelfont=:bold, ylabelfont=:bold)
  mytheme = Theme(fontsize=30, Axis=kw_axes)
  set_theme!(mytheme)
end

function set_xticks!(ax, dates)
  dateticks = optimize_ticks(dates[1], dates[end])[1]
  ax.xticks[] = (datetime2rata.(dateticks), Dates.format.(dateticks, "yyyy-mm-dd"))
end


function split_data(dates, vals, QC_flag)
  level_names_r = ["good", "marginal", "snow", "cloud", "aerosol", "shadow"]

  flgs = factor(level_names_r)
  qc_shape = [:circle, :rect, :xcross, :dtriangle, :dtriangle, :utriangle]
  qc_colors = ["grey60", "#00BFC4", "#F8766D", "#C77CFF", "#B79F00", "#C77CFF"]

  res = Dict()
  for i = 1:6
    ind = QC_flag .== flgs[i]
    x = dates[ind]
    y = vals[ind]
    r = (; x, y,
      strokewidth=1,
      strokecolor=qc_colors[i],
      label=level_names_r[i],
      color=qc_colors[i],
      marker=qc_shape[i]
    )
    res[level_names_r[i]] = r
  end
  res
end

function makie_plot_input(ax, d::DataFrame; plts=nothing, kw...)
  dates = d.date
  vals = d.y
  QC_flag = d.QC_flag
  dates = datetime2rata.(dates)
  res = split_data(dates, vals, QC_flag)
  names = ["good", "marginal", "snow", "cloud", "aerosol", "shadow"]
  
  init = false
  if plts === nothing 
    plts = Dict()
    plts["line"] = lines!(ax, dates, vals; color=:grey)
    init = true
  else
    plts["line"][1][] = Point.(dates, vals)
  end
  
  for name in names
    r = res[name]
    @unpack x, y, color, label, marker, strokecolor, strokewidth = r
    kw = (; color, label, marker, markersize=16, strokecolor, strokewidth=1)
    
    if init
      plts[name] = GLMakie.scatter!(ax, x, y; kw...)
    else
      length(x) == 0 && continue
      plts[name][1][] = Point.(x, y)
    end
  end
  init && axislegend(ax, position=:ct, orientation=:horizontal)
  plts
end

function makie_plot_fitting(ax, dfit; plts=nothing)
  colors = ["#00FF00" "#007F7F" "#0000FF" "#7F007F" "#FF0000"]
  iters = maximum(dfit.iter)

  init = false
  if plts === nothing
    plts=[]
    init=true
  end

  for i in 1:iters
    d = dfit[dfit.iter.==i, :]
    x = datetime2rata.(d.date)
    y = d.z
    if init
      p = lines!(ax, x, y,
        linewidth=2.5, color=colors[i], label="iter$i")
      push!(plts, p)
    else
      length(x) == 0 && continue
      plts[i][1][] = Point.(x, y)
    end
  end
  init && axislegend(ax, plts, string.("iter", 1:iters), position=:lt)
  plts
end
