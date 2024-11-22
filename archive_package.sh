#!/bin/sh

BASE=`pwd`
VER="v1.2"

PKG="AllocRiverGauge_${VER}"

########## make package directory ##########
rm -rf   $PKG
mkdir -p $PKG

########## copy adimin directories ##########
cp -r  adm $PKG
cp -r  doc $PKG

########## copy hires map data ##########
mkdir -p $PKG/hires_map
cp -r  hires_map/glb_30sec_pd8_v400 $PKG/hires_map/
cp -r  hires_map/jpn_05sec_pd8_v400 $PKG/hires_map/

cd $BASE/$PKG
ln -s ./hires_map/glb_30sec_pd8_v400 30sec_glb
ln -s ./hires_map/jpn_05sec_pd8_v400 05sec_jpn

cd $BASE

########## copy lowres map data ##########
mkdir -p $PKG/map
cp -r  map/glb_15min $PKG/map/
cp -r  map/tej_01min $PKG/map/
cp -r  map/src       $PKG/map/

mkdir -p $PKG/map/data
cp map/data/GRanD*    $PKG/map/data
cp map/data/GRDC*     $PKG/map/data
cp map/data/MLIT*     $PKG/map/data

cd $BASE/$PKG/map/glb_15min/src_param
make clean

cd $BASE/$PKG/map/tej_01min/src_param
make clean

cd $BASE/$PKG/map/src/src_param
make clean

cd $BASE

########## copy gauge list data ##########
mkdir -p $PKG/input
cp input/GRanD*    $PKG/input/
cp input/GRDC*     $PKG/input/
cp input/MLIT*     $PKG/input/

mkdir -p $PKG/output
cp output/GRanD*    $PKG/output/
cp output/GRDC*     $PKG/output/
cp output/MLIT*     $PKG/output/


########## copy source code ##########
cp -r  src $PKG
cd $BASE/$PKG/src
make clean

cd $BASE

cp s00-*.sh $PKG
cp s01-*.sh $PKG
cp s02-*.sh $PKG
cp s03-*.sh $PKG
cp s04-*.sh $PKG

cp archive_package.sh $PKG
cp ReadMe.md  $PKG
cp LICENSE    $PKG

######
echo "Copy complete"
echo "Prepare regionalized map, and then make package by archive_pkg.sh"

