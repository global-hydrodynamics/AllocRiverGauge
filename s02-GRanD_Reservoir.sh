#!/bin/sh
# allocate gauge (ID, lat, lon, uparea) on 01min MERIT river network
REGION=global01
#REGION=japan05

mkdir -p output

#================================================
## Round 1a: Allocate using original data
# (Input data)
# GRanD_original_v13GeoDAR.csv
# - original list of GRanD gauging station, contains ID, lat, lon, area, StationName, RivernName, etc (provided in 2019Dec)
#
# (Tentative output data): ./output/GRanD_alloc_1st.txt

./src/alloc_gauge_latlon_area  ./input/GRanD_original_v13GeoDAR.csv    $REGION
mv ./gauge_alloc.txt ./output/GRanD_alloc_1st.txt

echo "1st step data saved as ./output/GRanD_alloc_1st.txt"

# Round 1b: modification
# Visual inspection and manual correction.
#  Sample correction data is in GRanD_QC.xlsx (QCQA_1stRound sheet), and explained in the word manual. 
#  Modified list is saved as GRanD_tmp_modified.csv


#================================================
## Round 1a: Allocate using modified data
# (Input data)
# GRanD_tmp_modified.csv : gauge attributes with obvious error are modified

./src/alloc_gauge_latlon_area  ./input/GRanD_tmp_modified.csv    $REGION
mv ./gauge_alloc.txt ./output/GRanD_alloc_2nd.txt

echo "2nd step data saved as ./output/GRanD_alloc_2nd.txt"

# Round 2b: modification
# Visual inspection and manual correction.
#  Sample correction data is in GRanD_QC.xlsx (QCQA_2ndRound sheet), and explained in the word manual. 
#  Modified list is saved as GRanD_tmp2_modified.csv

#================================================
## Round-3a: Allocate using modified data
# (Input data)
# GRanD_tmp2_modified.csv : gauge uparea is replaced by MERIT-Hydro based uparea to minimize location shift due to uparea bias

./src/alloc_gauge_latlon_area  ./input/GRanD_tmp2_modified.csv    $REGION
mv ./gauge_alloc.txt ./output/GRanD_alloc_3nd.txt

echo "3rd step data saved as ./output/GRanD_alloc_3rd.txt"

#================================================
## Finalize-1: check the finalized allocated data
# (Input data1) output/GRanD_alloc_3rd.txt   : finalized gauges allocatred on MERIT Hydro
# (Input data2) input/GRanD_tmp_modified.csv : modified location in column 2-4, original location in colum 5-7

./src/check_gauge_latlon_area  ./output/GRanD_alloc_3nd.txt  ./input/GRanD_tmp_modified.csv
mv ./gauge_alloc.txt ./output/GRanD_alloc_final.txt

echo "final step data saved as ./output/GRanD_alloc_final.txt"

# Finalize-2
# Sample data for manual quality assessment is in GRanD_QCQA.xlsx 
# The finalized data is in (QCQA_finalized sheet). 
#   The lat_MERIT, lon_MERIT, area_MERIT represents the gauge locaion data allocated on MERIT Hydro.
#   The finalized version of GRanD allocated list is saved as GRanD_allocated.csv

python ./src/extract_GRanD.py

echo "Finalized CSV, with extracted attribute for CaMa-Flood saved as ./input/GRanD_allocated.csv"
