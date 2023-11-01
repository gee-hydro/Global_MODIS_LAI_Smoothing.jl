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

function makie_plot_input!(ax, dates, vals, QC_flag; kw...)
  dates = datetime2rata.(dates)
  base_size = 4.5
  level_names_r = ["good", "marginal", "snow", "cloud", "aerosol", "shadow"]

  flgs = factor(level_names_r)
  qc_shape = [:circle, :rect, :xcross, :dtriangle, :dtriangle, :utriangle]
  qc_colors = ["grey60", "#00BFC4", "#F8766D", "#C77CFF", "#B79F00", "#C77CFF"]
  qc_size = [0.5, 0.5, 0.5, 0, 0, 0] .+ base_size

  lines!(ax, dates, vals; color=:grey)
  for i = 1:6
    ind = findall(QC_flag .== flgs[i])
    GLMakie.scatter!(ax, dates[ind], vals[ind];
      markersize=qc_size[i] + 16,
      strokewidth=1,
      strokecolor=qc_colors[i],
      label=level_names_r[i],
      color=qc_colors[i],
      marker=qc_shape[i]
    )
  end
  axislegend("", position=:ct, orientation=:horizontal)
end

makie_plot_input!(ax, d::DataFrame; kw...) =
  makie_plot_input!(ax, d.date, d.y, d.QC_flag; kw...)

function makie_plot_fitting!(ax, dfit)
  colors = ["#00FF00" "#007F7F" "#0000FF" "#7F007F" "#FF0000"]
  plts = []
  iters = maximum(dfit.iter)

  for i in 1:iters
    d = dfit[dfit.iter.==i, :]
    plt = lines!(ax, datetime2rata.(d.date), d.z,
      linewidth=2.5, color=colors[i], label="iter$i")
    push!(plts, plt)
  end
  axislegend(ax, plts, string.("iter", 1:iters), position=:lt)
end
