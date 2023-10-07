using Zarr, YAXArrays
import YAXArrays.Datasets: Dataset

Base.names(ds::Dataset) = string.(collect(keys(ds.cubes)))
Base.getindex(ds::Dataset, i) = ds[names(ds)[i]]
chunksize(cube) = Cubes.cubechunks(cube)
chunksize(ds::Dataset) = chunksize(ds[1])
