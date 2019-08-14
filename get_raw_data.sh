#!/bin/bash

LOGS=".dl_raw_data_logs"
DLD_URL="https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot/"
LOC_FLD="/ext_data/stas/ECHO/PM/scrna-seq"

if [ ! -d "$LOGS" ]; then
  mkdir "$LOGS"
fi


./../dl_raw_data.sh -t $LOC_FLD -u $DLD_URL -c 2 -d 2>&1 | tee "$LOGS/$(date +"%Y%m%d_%H%M%S").log"
#./../dl_raw_data.sh -h -d 2>&1 | tee "$LOGS/$(date +"%Y%m%d_%H%M%S").log"


#./dl_raw_data.sh -t /ext_data/stas/ECHO/PM/scrna-seq -u https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot/ -c 2 -d &>> "$LOGS/$(date +"%Y%m%d_%H%M%S").log"
#./dl_raw_data.sh -h >> "$LOGS/$(date +"%Y%m%d_%H%M%S").log" #for testing only
#2>&1 | tee - allows display starndard and error output on screen and into a file