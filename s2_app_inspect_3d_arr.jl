includet("src/main_makie.jl")

## 1. 加载数据 ------------------------------------------------------------------
f = "H:/VNP15A2H-LAI_240deg_nc/VNP15A2H-LAI_240deg_global_2022_2_3.nc"
nc = nc_open(f)
LAI = nc["LAI"]

lon = nc["lon"][:]
lat = nc["lat"][:]
time = nc["time"][:]

cellx = lon[2] - lon[1]
celly = abs(lat[2] - lat[1])

## 2. 绘图 --------------------------------------------------------------------
my_theme!(font_size=24)
style_line = (; linestyle=:dash, color=:red, linewidth=2)

fig = Figure(resolution=(1900, 800), outer_padding=2) # figure_padding = 10

sg = SliderGrid(fig[1, 2], (label="time", range=time, startvalue=middle(time)))
stime = sg.sliders[1].value
slon = Observable(middle(lon))
slat = Observable(middle(lat))

i = @lift findnear(lon, $slon)[2]
j = @lift findnear(lat, $slat)[2]
k = @lift findnear(time, $stime)[2]

str_pos = @lift @sprintf("Position: i=%d, j=%d", $i, $j)
label_pos = Label(fig[1, 1], str_pos, fontsize=30, tellwidth=false)

z = @lift LAI[$i, $j, :]
mat_z = @lift LAI[:, :, $k]

## 时间序列图
ax_time = Axis(fig[2, 1], title=@lift(@sprintf("时间序列图: time = %d", $stime)),
  xlabel="DOY")
# plot!(ax5, time, zs, label="China")
lines!(ax_time, time, z, label="Pixel", color=:blue)
vlines!(ax_time, k; style_line...) # , zs[$k]

## 空间图
plot_main = fig[2, 2]
ax_xy = Axis(plot_main, title=@lift(@sprintf("XY剖面图: time = %d", $stime)),
  # yticks=15:10:55,
  xlabel="Latitude", ylabel="Longitude")

handle = big_heatmap!(ax_xy, lon, lat, mat_z)
Colorbar(fig[:, 0], handle_hm, height=Relative(0.5))
vlines!(ax_xy, slon; style_line...)
hlines!(ax_xy, slat; style_line...)

map_on_mouse(fig, handle, slon, slat)
map_on_keyboard(fig, slon, slat, stime, cellx, celly; step=500)

colgap!(fig.layout, 0)
rowgap!(fig.layout, 0)

fig
