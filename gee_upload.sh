#! /usr/bin/bash
# 

dir_root=$(dirname "$0")
dir_root=`realpath "$dir_root"`

meta=$dir_root/gee_info.csv
indir=$dir_root/OUTPUT/GEE

echo "indir: $indir"

# geeup getmeta --input $indir --metadata $meta
user="kjding93@gmail.com"
col=projects/gee-hydro/MODIS_Terra_LAI/global_param_lambda_cv

geeup upload --source $indir --dest $col -m $meta --nodata 0 -u $user

# options:
#   -h, --help            show this help message and exit

# Required named arguments.:
#   --source SOURCE       Path to the directory with images for upload.
#   --dest DEST           Destination. Full path for upload to Google Earth
#                         Engine image collection, e.g.
#                         users/pinkiepie/myponycollection
#   -m METADATA, --metadata METADATA
#                         Path to CSV with metadata.
#   -u USER, --user USER  Google account name (gmail address).

# Optional named arguments:
#   --nodata NODATA       The value to burn into the raster as NoData
#                         (missing data)
#   --mask {True,False,t,f}
#                         Binary to use last band for mask True or False
#   --pyramids PYRAMIDS   Pyramiding Policy, MEAN, MODE, MIN, MAX, SAMPLE
#   --overwrite OVERWRITE
#                         Default is No but you can pass yes or y
