#!/bin/sh
# allocate gauge (ID, lat, lon, uparea) on 01min MERIT river network
REGION=global30
#REGION=japan05

mkdir -p output

#================================================
## Round 1a: Allocate using original data

# (Input data)
# GRDC_original_2019Dec.csv
# - original list of GRDC gauging station, contains ID, lat, lon, area, StationName, RivernName, etc (provided in 2019Dec)
#
# (Tentative output data): ./output/GRDC_alloc_1st.txt

./src/alloc_gauge_latlon_area  ./input/GRDC_original_2019Dec.csv    $REGION
mv ./gauge_alloc.txt ./output/GRDC_alloc_1st.txt

echo "1st step data saved as ./output/GRDC_alloc_1st.txt"

## Round 1b qualoity control on Excel
# Visual inspection and manual correction.
#  Sample correction data is in GRDC_QC.xlsx (QCQA_1stRpoud sheet), and explained in the word manual. 
#  Modified list is saved as GRDC_tmp_modified.csv

#================================================
## Round 2a: Allocate using modified data
# (Input data)
# GRDC_tmp_modified.csv : gauge attributes with obvious error are modified

./src/alloc_gauge_latlon_area  ./input/GRDC_tmp_modified.csv    $REGION
mv ./gauge_alloc.txt ./output/GRDC_alloc_2nd.txt

echo "2nd step data saved as ./output/GRDC_alloc_2nd.txt"

## Round 2b qualoity control on Excel
# Visual inspection and manual correction.
#  Sample correction data is in GRDC_QC.xlsx (QCQA_2ndRpoud sheet), and explained in the word manual. 
#  Modified list is saved as GRDC_tmp2_modified.csv

#================================================
## Round 3a: Allocate using modified data
# (Input data)
# GRDC_tmp2_modified.csv : gauge uparea is replaced by MERIT-Hydro based uparea to minimize location shift due to uparea bias

./src/alloc_gauge_latlon_area  ./input/GRDC_tmp2_modified.csv    $REGION
mv ./gauge_alloc.txt ./output/GRDC_alloc_3rd.txt

echo "3rd step data saved as ./output/GRDC_alloc_3rd.txt"

## Round 3b qualoity control on Excel
# Visual inspection and manual correction.
#  Sample correction data is in GRDC_QC.xlsx (QCQA_3rdRpoud sheet), and explained in the word manual. 


#================================================
## FInalize: check the finalized allocated data
# (Input data1) output/GRDC_alloc_3rd.txt   : finalized gauges allocatred on MERIT Hydro
# (Input data2) input/GRDC_tmp_modified.csv : modified location in column 2-4, original location in colum 5-7

./src/check_gauge_latlon_area  ./output/GRDC_alloc_3rd.txt  ./input/GRDC_tmp_modified.csv
mv ./gauge_alloc.txt ./output/GRDC_alloc_final.txt

echo "final step data saved as ./output/GRDC_alloc_final.txt"

# Finalize
# Sample data for manual quality assessment is in GRDC_QCQA.xlsx 
# The finalized data is in (QCQA_finalized sheet). 
#   The lat_MERIT, lon_MERIT, area_MERIT represents the gauge locaion data allocated on MERIT Hydro.
#   The finalized version of GRDC allocated list is saved as GRDC_allocated.csv



