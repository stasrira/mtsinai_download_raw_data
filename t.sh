#!/bin/bash
#me=${0##*/}
#echo $me
ME=$(echo "${0##*/}" | cut -f 1 -d '.') #get name of the file it is running from
echo $ME
LOGS=$ME"_logs"
echo $LOGS
LOG_FILE=$(date +"%Y%m%d_%H%M%S")".log"
echo $LOG_FILE

for filename in ./get_raw_data_ECHO_PM_scRNAseq_logs/*.*; do
	echo $filename
done

#ls -1 | wc -l
#t=ls "./get_raw_data_ECHO_PM_scRNAseq_logs/*.log" -1 | wc -l
echo "find files starts here ============"
#find ./get_raw_data_ECHO_PM_scRNAseq_logs/ -name "*.tar"
files=$(find ./get_raw_data_ECHO_PM_scRNAseq_logs/ -name "*.tar")
for file in $files
do
	echo $file
done
