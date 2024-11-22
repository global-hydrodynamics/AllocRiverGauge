#!/bin/sh
# Allocate River Level Gaunge to CaMa-Flood river network
########################################
# Sample allocating MLIT level gauge 
GAUGEINP='../../data/MLIT_LevelGauge_allocated.csv'               # Gauge List File

GAUGEOUT='../MLIT_LevelGauge.txt' # correctly allocated on river network

./allocate_level_gauge $GAUGEINP

mv ./gauge_alloc.txt $GAUGEOUT
