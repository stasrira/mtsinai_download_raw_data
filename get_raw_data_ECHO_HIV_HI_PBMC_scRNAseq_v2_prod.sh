#!/bin/bash
#========================
#verify the set value for the follwoing variables, to make sure that they point to correct locations
DL_TOOL_LOC="./dl_raw_data.sh" #path to the download tool
ARCH_TOOL_LOC="./arch_logs.sh"
#array of remote web folders where from data is picked up
declare -a DLD_URLS=("https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/727_AS07_10643_1/"
					"https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/728_FS07_06412_1/"
					"https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/729_AS08_02684_1/"
					"https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/730_AS09_13561_1/"
					"https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/731_AS09_14594-1/"
					"https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/732_AS10_02940-1/"
					"https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/733_AS11_12162_1/"
					"https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/734_AS13_08590_1/"
)
TRG_FLD="/ext_data/shared/ECHO/HIV/HI/PBMC/scrna-seq" #local folder where to data is being downloaded
CUT_DIR=2 #number of web directories that will be cut off (starting from the domain name)
#========================

ME=$(echo "${0##*/}" | cut -f 1 -d '.') #get name of the file it is running from
LOG_FLD=$ME"_logs"
LOG_FILE=$(date +"%Y%m%d_%H%M%S")".log"

#check if LOG_FLD exists, if not, create a new folder
if [ ! -d "$LOG_FLD" ]; then
  mkdir "$LOG_FLD"
fi

#invoke dl_raw_data.sh file to load any new data availalble for the given web folder vs. local folder
#it will run a loop to get one entry at a time from DLD_URLS array
for dldurl in "${DLD_URLS[@]}"
do
   echo "Processing URL: $dldurl"
   #run the download tool for each of the URLs
   $DL_TOOL_LOC -t $TRG_FLD -u $dldurl -c $CUT_DIR -d 2>&1 | tee "$LOG_FLD/$LOG_FILE"
   #old version - $DL_TOOL_LOC -t $TRG_FLD -u $DLD_URL -c $CUT_DIR -d 2>&1 | tee "$LOG_FLD/$LOG_FILE"
done

#./../dl_raw_data.sh -h -d 2>&1 | tee "$LOGS/$(date +"%Y%m%d_%H%M%S").log"
#2>&1 | tee - allows display starndard and error output on screen and into a file

#invoke archiving tool to archive old log files except the most recent created one
$ARCH_TOOL_LOC -d -f $LOG_FLD -e $LOG_FILE
