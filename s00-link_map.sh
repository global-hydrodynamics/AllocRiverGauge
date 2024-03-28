#!/bin/sh
# This is the code used to prepare the sample river map data.
#
# prepare CaMa-Flood map (global 1min, Japan 15sec, Japan 05sec) on which gauges are allocated.
# note: allocation on coarser resolution river map can be done in CaMa-Flood package, using the output from this script.

BASE=`pwd`

cd $BASE

#======================
echo "Copy or Link High-resolution River Map"
mkdir -p hires_map

MAPGLB='./hires_map/glb_30sec_pd8_v400'
MAPJPN='./hires_map/jpn_05sec_pd8_v400'

## Copy from original data
#CMFGLB="/Users/yamadai/work/FLOW/d8_30sec/glb_30sec_pd8"
#CMFJPN="/Users/yamadai/work/FLOW/d8_jp_05sec/jpn_05sec_pd8"
#
#cd hires_map
#mkdir -p $MAPGLB
#mkdir -p $MAPJPN
#
#cp ${CMFGLB}/elevtn.??? $MAPGLB/
#cp ${CMFGLB}/nextxy.??? $MAPGLB/
#cp ${CMFGLB}/uparea.??? $MAPGLB/
#cp ${CMFGLB}/width.???  $MAPGLB/
#cp ${CMFGLB}/params.txt $MAPGLB/
#
#cp ${CMFJPN}/elevtn.??? $MAPJPN/
#cp ${CMFJPN}/nextxy.??? $MAPJPN/
#cp ${CMFJPN}/uparea.??? $MAPJPN/
#cp ${CMFJPN}/width.???  $MAPJPN/
#cp ${CMFJPN}/params.txt $MAPJPN/
#

## Link high-res map
cd $BASE

ln -sf $MAPGLB 30sec_glb
ln -sf $MAPJPN 05sec_jpn

#=============
cd $BASE

#======================
echo "Copy source code to glb_15min & tej_01min"
cd map

# Copy mapdata from CaMa-Flood package (glb_15min, tej_01min)

cp -r src/src_param glb_15min
cp -r src/src_param tej_01min
