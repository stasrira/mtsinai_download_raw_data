#!/bin/bash
#========================
#verify the set value for the follwoing variables, to make sure that they point to correct locations
DL_TOOL_LOC="./dl_raw_data.sh" #path to the download tool
ARCH_TOOL_LOC="./arch_logs.sh"
#array of remote web folders where from data is picked up
#declare -a DLD_URLS=("https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/096_ATACseq_AS10_07990_2/outs/summary.csv"
#)
#TRG_FLD="/ext_data/shared/ECHO/HIV/HI/PBMC/scrna-seq" #local folder where to data is being downloaded
CUT_DIR=3 #number of web directories that will be cut off (starting from the domain name)
#========================

pwd

file=./data_transfers_requests/data_transfer_request.tsv

#to remove Windows line endings 
sed -i 's/\r$//' "$file"

#file="data_transfers_requests\data_transfer_request.tsv"

#awk '{print "source="$1"\tdestination="$2}' $file

#exit 0

printf "========IFS\n"
# set the Internal Field Separator to |
# IFS='\t'
CNT=0
while read -r dldurl TRG_FLD LOC_NAME
do
		echo $CNT
        if [ ! "$CNT" -eq "0" ]; then
			echo "source: $dldurl"
			echo "destination: $TRG_FLD"
			echo "local name: $LOC_NAME"
			
			#replace return character
			#tr '\r' '' <<<"$TRG_FLD"
			#tr '\r' '' <<<"$LOC_NAME"
			
			FINAL_TRG_FLD=$TRG_FLD/$LOC_NAME
			echo "final destination: $FINAL_TRG_FLD"
			
			ME=$(echo "${0##*/}" | cut -f 1 -d '.') #get name of the file it is running from
			LOG_FLD=logs/$ME"_logs"
			LOG_FILE=$(date +"%Y%m%d_%H%M%S")_$LOC_NAME".log"
			echo "LOG_FLD: $LOG_FLD"
			echo "LOG_FILE: $LOG_FILE"
			
			#check if LOG_FLD exists, if not, create a new folder
			mkdir -p "$LOG_FLD"
			#if [ ! -d "$LOG_FLD" ]; then
			#  mkdir "$LOG_FLD"
			#fi
			echo "Log folder was verified: $LOG_FLD"
			echo "Processing URL: $dldurl"
			#run the download tool for each of the URLs
			$DL_TOOL_LOC -t $FINAL_TRG_FLD -u $dldurl -c $CUT_DIR -d 2>&1 | tee "$LOG_FLD/$LOG_FILE"

			#./../dl_raw_data.sh -h -d 2>&1 | tee "$LOGS/$(date +"%Y%m%d_%H%M%S").log"
			#2>&1 | tee - allows display starndard and error output on screen and into a file

			#invoke archiving tool to archive old log files except the most recent created one
			#$ARCH_TOOL_LOC -d -f $LOG_FLD -e $LOG_FILE
		fi
		CNT=$((CNT+1))

done < "$file"

exit 0




ME=$(echo "${0##*/}" | cut -f 1 -d '.') #get name of the file it is running from
LOG_FLD=$ME"_logs"
LOG_FILE=$(date +"%Y%m%d_%H%M%S")".log"

#check if LOG_FLD exists, if not, create a new folder
mkdir -p "$LOG_FLD"
#if [ ! -d "$LOG_FLD" ]; then
#  mkdir "$LOG_FLD"
#fi

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
