#!/bin/sh
# Allocate River Flow Gaunge to CaMa-Flood river network
########################################
# Sample allocating GRDC river flow gauges 

GAUGEINP='../../data/MLIT_FlowGauge_alloc_final.csv'               # Gauge List File
GAUGEOUT='../MLIT_FlowGauge.txt'

./allocate_flow_gauge $GAUGEINP multi
mv ./gauge_alloc.txt $GAUGEOUT
