github = "https://github.com/jl-pkgs"

pkgs = [
  "GLMakie", 
  "Colors", 
  "JLD2", "JSON",
  "DimensionalData",
  "Rasters",
  "Zarr", 
  "DiskArrays",
  "NCDatasets", 
  "NetCDF", 
  "Parameters", 
  "ProgressMeter", 
  "DataFrames",
  "https://github.com/eco-hydro/Whittaker2.jl",
  "$github/Terra"
  "$github/NetCDFTools",
  "$github/RTableTools"
  "$github/Ipaper"]

using Pkg
Pkg.add(pkgs)
