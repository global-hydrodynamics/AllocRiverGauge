#!/bin/sh
# allocate flow gauge (ID, lat, lon) on 05sec Japan river network. No upstream area

#REGION=global01
REGION=japan05

UPATHRS=1.0  ## Uparea threshold of pixels to allocate gauges [km2]

mkdir -p output

#================================================
## Round 1a: Allocate using original data
# (Input data)
# MLIT_FlowGauge__original.csv
# - original list of Japan MLIT flow gauges, contains ID, lat, lon, area
#
# (Tentative output data): ./output/MLIT_FlowGauge_alloc_1st.txt

./src/alloc_gauge_latlon_opt  ./input/MLIT_FlowGauge_original.csv  $UPATHRS  $REGION
mv ./gauge_alloc.txt ./output/MLIT_FlowGauge_alloc_1st.txt
# echo "1a step data saved as ./output/MLIT_FlowGauge_alloc_1st.txt"

## Round 1c: select allocation results judging from smaller area_score
# Visual inspection and manual correction.
#  Sample correction data is in MLIT_QCQA.xlsx (QCQA_1stRound sheet), and explained in the word manual. 
#  Modified list is saved as MLIT_FlowGauge_tmp1_modified.csv

#================================================
## Round 2a: Allocate using modified data
# (Input data)
# MLIT_FlowGauge_tmp1_modified.csv : gauge attributes with obvious error are modified

./src/alloc_gauge_latlon_area  ./input/MLIT_FlowGauge_tmp1_modified.csv    $REGION
mv ./gauge_alloc.txt ./output/MLIT_FlowGauge_alloc_2nd.txt
# echo "2nd step data saved as ./output/MLIT_FlowGauge_alloc_2nd.txt"

#================================================
## FInalize: check the finalized allocated data
# (Input data1) output/MLIT_FlowGauge_alloc_2nd.txt   : finalized gauges allocatred on MERIT Hydro
# (Input data2) input/MLIT_FlowGauge_tmp_modified.csv : modified location in column 2-4, original location in colum 5-7

./src/check_gauge_latlon_area  ./output/MLIT_FlowGauge_alloc_2nd.txt  ./input/MLIT_FlowGauge_modified.csv
mv ./gauge_alloc.txt ./output/MLIT_FlowGauge_alloc_final.txt
echo "Finalized CSV, with extracted attribute for CaMa-Flood saved as ./output/MLIT_FlowGauge_alloc_final.txt"

