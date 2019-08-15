#!/bin/bash
#========================
#verify the set value for the follwoing variables, to make sure that they point to correct locations
DL_TOOL_LOC="./dl_raw_data.sh" #path to the download tool
ARCH_TOOL_LOC="./arch_logs.sh"
DLD_URL="https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00814_TechDev_Duke_collab/" #remote web folder where from data is picked up
TRG_FLD="/ext_data/shared/ECHO/DU/HLTH/scrna-seq" #local folder where to data is being downloaded
#========================

ME=$(echo "${0##*/}" | cut -f 1 -d '.') #get name of the file it is running from
LOG_FLD=$ME"_logs"
LOG_FILE=$(date +"%Y%m%d_%H%M%S")".log"

#check if LOG_FLD exists, if not, create a new folder
if [ ! -d "$LOG_FLD" ]; then
  mkdir "$LOG_FLD"
fi

#invoke dl_raw_data.sh file to load any new data availalble for the given web folder vs. local folder
$DL_TOOL_LOC -t $TRG_FLD -u $DLD_URL -c 2 -d 2>&1 | tee "$LOG_FLD/$LOG_FILE"
#./../dl_raw_data.sh -h -d 2>&1 | tee "$LOGS/$(date +"%Y%m%d_%H%M%S").log"
#2>&1 | tee - allows display starndard and error output on screen and into a file

#invoke archiving tool to archive old log files except the most recent created one
$ARCH_TOOL_LOC -d -f $LOG_FLD -e $LOG_FILE
