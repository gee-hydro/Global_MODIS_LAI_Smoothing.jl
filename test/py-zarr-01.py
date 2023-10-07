# %%
import dask
import xarray as xr

# filename = "your_input.nc"
f = "/mnt/z/MODIS/Terra_LAI_v061_nc/MOD15A2H_v061-raw2-LAI_240deg_global_2018_2_3.nc"
ds = xr.open_dataset(f)
ds

# %%
output_path = "INPUT/py-zarr-01.zarr"
ds.to_zarr(output_path, mode='w', consolidated=True)
