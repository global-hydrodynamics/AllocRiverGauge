#!/bin/sh
# allocate water level gauge (ID, lat, lon) on 05sec Japan river network. No upstream area

#REGION=global01
REGION=japan05

UPATHRS=1.0  ## Uparea threshold of pixels to allocate gauges [km2]

mkdir -p output

#================================================
## Round 1a: Allocate using original data
# (Input data)
# MLIT_LevelGauge_original.csv
# - original list of Japan MLIT water level gauges, contains ID, lat, lon, (no area)
#
# (Tentative output data): ./output/MLIT_LevelGauge_alloc_1st.txt

./src/alloc_gauge_latlon_only  ./input/MLIT_LevelGauge_original.csv  $UPATHRS  $REGION
mv ./gauge_alloc.txt ./output/MLIT_LevelGauge_alloc_1st.txt

echo "1st step data saved as ./output/GRanD_alloc_1st.txt"

## Round 1b: quality check
# Visual inspection and manual correction.
#  Sample correction data is in MLIT_LevelGauge_QCQA.xlsx (QCQA_1stRpoud sheet), and explained in the word manual. 
#  Modified list is saved as MLIT_LevelGauge_tmp1_modified.csv

#================================================
## Round 2a: Allocate using modified data
# (Input data)
# MLIT_LevelGauge_tmp1_modified.csv : gauge attributes with obvious error are modified

./src/alloc_gauge_latlon_area  ./input/MLIT_LevelGauge_tmp1_modified.csv    $REGION
mv ./gauge_alloc.txt ./output/MLIT_LevelGauge_alloc_2nd.txt

echo "2nd step data saved as ./output/MLIT_LevelGauge_alloc_2nd.txt"

## Round 2b: quality check
# Visual inspection and manual correction.
#  Sample correction data is in MLIT_LevelGauge_QCQA.xlsx (QCQA_2ndRpoud sheet), and explained in the word manual. 
#  Modified list is saved as MLIT_LevelGauge_allocated.csv

echo "Finalized CSV, with extracted attribute for CaMa-Flood saved as ./input/MLIT_LevelGauge_allocated.csv"

