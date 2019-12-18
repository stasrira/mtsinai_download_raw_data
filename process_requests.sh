#!/bin/bash

set -euo pipefail

#version of the script
_VER_NUM=1.01
_VERSION="`basename ${0}` (version: $_VER_NUM)" 

_HELP="\n$_VERSION
	\n\narguments usage: 
		\n\t[-v: report the version; if this argument is supplied, it aborts execution of the script]
		\n\t[-h: help; if this argument is supplied, it aborts execution of the script]
		\n\t[-d: debug version]
		\n\t[-f path to folder that will contain Download Request files (of predefined format); this is a required parameter
		\n\t\tRequest files have to be a tab-delimited text files.
		\n\t\tEach row of the file contains one download request, where 
		\n\t\t\t- First argument provides URL to the data to be downloaded.
		\n\t\t\t- Second argument specifies path to the location where downloaded data will be saved.
		\n\t\t\t- Third argument specifies the folder name that will be created in the given path; all downloaded data will be save in this folder.
		\n\t[-s: pattern that will be used to search for Download Request files in the given folder]
		\n
		"

#verify the set value for the follwoing variables, to make sure that they point to correct locations
DL_TOOL_LOC="./dl_raw_data.sh" #path to the download tool
ARCH_TOOL_LOC="./arch_logs.sh"
#array of remote web folders where from data is picked up
#declare -a DLD_URLS=("https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/096_ATACseq_AS10_07990_2/outs/summary.csv"
#)
#TRG_FLD="/ext_data/shared/ECHO/HIV/HI/PBMC/scrna-seq" #local folder where to data is being downloaded

COPY_METHODS=(wget cp) # array of expected methods to be used for data copying
COPY_METHOD_WGET_FILTER=("http://" "https://")
COPY_METHOD_INPUT="" #"" is a default value; other expected value are "wget cp"
COPY_METHOD=""

CUT_DIR=0 #default number of web directories that will be cut off (starting from the domain name)
CUT_DIR_STANDARD_DEDUCTION=2 #2 stands for number of elements after parcing the URL that reflects HTTP and main domain parts
MAIN_LOG="logs"
PROCESSED_FLD="processed"
REQ_FOLDER=""
SRCH_MAP="*.tsv"
GRP="data"
_PD=0

#Email parameters
smtp="smtp.mssm.edu:25"
to_emails="stasrirak.ms@gmail.com,stas.rirak@mssm.edu"
from_email="stas.rirak@mssm.edu"

#identify locations and names of log_folder for this run
ME=$(echo "${0##*/}" | cut -f 1 -d '.') #get name of the file it is running from
LOG_FLD=$MAIN_LOG/$(date +"%Y%m%d_%H%M%S")_$ME"_logs"
REQ_LOG_FILE=$LOG_FLD/$(date +"%Y%m%d_%H%M%S")"_process_log.txt"
REQ_ERROR_LOG_FILE=$LOG_FLD/$(date +"%Y%m%d_%H%M%S")"_error_log.txt"
echo "Log folder for this request: " $LOG_FLD

CREATED_LOG_FILES=$(basename $REQ_LOG_FILE)
ATTCH_REQUESTS=""
PROC_REQS=""

#check if LOG_FLD exists, if not, create a new folder
mkdir -p "$LOG_FLD"


#analyze received arguments
while getopts f:s:m:dvh o
do
    case "$o" in
	f) REQ_FOLDER="$OPTARG";;
	s) SRCH_MAP="$OPTARG";;
	m) COPY_METHOD_INPUT="$OPTARG";;
	d) _PD="1";;
	v) echo -e $_VERSION
	   exit 0;;
	h) echo -e $_HELP
	   exit 0;;
	*) echo "$0: invalid option -$o" >&2
	   echo -e $_HELP
	   exit 1;;
    esac
done
shift $((OPTIND-1))

if [ "$_PD" == "1" ]; then #output in debug mode only
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->REQ_FOLDER (-f): " $REQ_FOLDER  | tee -a "$REQ_LOG_FILE"
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->SRCH_MAP (-s): " $SRCH_MAP  | tee -a "$REQ_LOG_FILE"
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->COPY_METHOD_INPUT (-m): " $COPY_METHOD_INPUT  | tee -a "$REQ_LOG_FILE"
fi

if [ "$REQ_FOLDER" == "" ]; then
	#if folder parameter was not provided, abourt the operation
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Locaiont of the request folder was not provided ('-f' parameter), aborting the process!" | tee -a "$REQ_LOG_FILE"
	exit 1
fi

# raise error if a $COPY_METHOD_INPUT is not blank and not one of the expected values
if [[ ! " ${COPY_METHODS[@]} " =~ " ${COPY_METHOD_INPUT} " ]] && [ ! "$COPY_METHOD_INPUT" == "" ]; then
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Unexpected value '$COPY_METHOD_INPUT' was provided for the copy method ('-m' parameter), aborting the process! Expected values are '${COPY_METHOD_WGET_FILTER[*]}'." | tee -a "$REQ_LOG_FILE"
	exit 1
fi

#loop through all files (based on a map) in the given folder (it will not go into the subfolders)
FILES=$(find $REQ_FOLDER -maxdepth 1 -name "$SRCH_MAP")

for file in $FILES
do
	#file=./data_transfers_requests/data_transfer_request.tsv
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->Start of processing file: " $file | tee -a "$REQ_LOG_FILE"
	fi

	#to remove Windows line endings 
	sed -i 's/\r$//' "$file"
	
	#verify that the file has end of line as the very last character in the file
	#it is needed to makesure that the last line of the file will be executed
	[ -n "$(tail -c1 $file)" ] && printf '\n' >>$file 

	#CREATED_LOG_FILES=""

	CNT=0
	while read -r dldurl TRG_FLD LOC_NAME
	do
		if [ "$_PD" == "1" ]; then #output in debug mode only
			echo "$(date +"%Y-%m-%d %H:%M:%S")-->Processing line #: $CNT" | tee -a "$REQ_LOG_FILE"
		fi
		if [ ! "$CNT" == "0" ]; then
			if [ "$_PD" == "1" ]; then #output in debug mode only
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Start processing download request for: " $LOC_NAME | tee -a "$REQ_LOG_FILE"
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->source: $dldurl" | tee -a "$REQ_LOG_FILE"
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->requested destination: $TRG_FLD" | tee -a "$REQ_LOG_FILE"
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->requested local name: $LOC_NAME" | tee -a "$REQ_LOG_FILE"
			fi
			
			# if any of the provided values is blank, the system will skip this entry and go to the next one
			if [ "$dldurl" == "" ] || [ "$TRG_FLD" == "" ] || [ "$LOC_NAME" == "" ]; then
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Request entry line from a file does not have all expected values provided, skipping this line! Here are retrieved values: dldurl='$dldurl', TRG_FLD='$TRG_FLD', LOC_NAME='$LOC_NAME' " | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
				CNT=$((CNT+1))
				continue
			fi
			
			COPY_METHOD="" #reset COPY_METHOD value
			if [ "$COPY_METHOD_INPUT" == "" ]; then
				#if copy method parameter is blank, check if source path starts with 'https://' and assign 'wget', otherwise assign 'cp'
				for method_filter in ${COPY_METHOD_WGET_FILTER[*]}
				do
					# loop through to see if source value matching wget filter criteria
					if [[ "$dldurl" =~ ^"${method_filter}".* ]]; then
						COPY_METHOD="wget"
					fi
				done
				#if there was no match for the wget filter and $COPY_METHOD is still blank assign cp as defaul
				if [ "$COPY_METHOD" == "" ]; then
					COPY_METHOD="cp"
				fi
			else
				# assign passed value for the copy method
				COPY_METHOD=$COPY_METHOD_INPUT
			fi
			
			if [ "$_PD" == "1" ]; then #output in debug mode only
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Final copy method to be used: '$COPY_METHOD'" | tee -a "$REQ_LOG_FILE"
			fi
			
			# exit 0 # for testing only ==========================
			
			#identify number of subfolders in the URL
			elements=$(echo $dldurl | tr "/" "\n") #split URL by "/"
			el_cnt=0
			for el in $elements; do 
				el_cnt=$((el_cnt+1))
			done
			if [ "$el_cnt" -ge "2" ]; then
				CUT_DIR=$((el_cnt-CUT_DIR_STANDARD_DEDUCTION)) #calculate number of sub directories in URL
			fi
			
			FINAL_TRG_FLD=$TRG_FLD/$LOC_NAME
			if [ "$_PD" == "1" ]; then #output in debug mode only
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Final number of dirs to be cut = "$CUT_DIR | tee -a "$REQ_LOG_FILE"
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->final destination: $FINAL_TRG_FLD" | tee -a "$REQ_LOG_FILE"
			fi

			#identify locations and names for log files
			LOG_FILE=$(date +"%Y%m%d_%H%M%S")_$LOC_NAME".log"
			if [ ! "$CREATED_LOG_FILES" == "" ]; then
				CREATED_LOG_FILES="${CREATED_LOG_FILES}:" #add a separator to list of files
			fi
			CREATED_LOG_FILES="${CREATED_LOG_FILES}${LOG_FILE}" #add a new log file to list of all created log files
			if [ "$_PD" == "1" ]; then #output in debug mode only
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Current Log Folder: $LOG_FLD" | tee -a "$REQ_LOG_FILE"
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Current Log File: $LOG_FILE" | tee -a "$REQ_LOG_FILE"
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->List of Log Files created for current request= "$CREATED_LOG_FILES | tee -a "$REQ_LOG_FILE"
			fi
			
			echo "$(date +"%Y-%m-%d %H:%M:%S")-->Start downloading tool => $DL_TOOL_LOC -t $FINAL_TRG_FLD -u $dldurl -c $CUT_DIR -m $COPY_METHOD -d" | tee -a "$REQ_LOG_FILE"
			#run the download tool for each of the URLs
			#next line commented for testing purposes only
			if $DL_TOOL_LOC -t $FINAL_TRG_FLD -u $dldurl -c $CUT_DIR -m $COPY_METHOD -d 2>&1 | tee "$LOG_FLD/$LOG_FILE"; then
			#if true; then # for testing purposes only
				if [ "$_PD" == "1" ]; then #output in debug mode only
					echo "$(date +"%Y-%m-%d %H:%M:%S")-->Successful finish of processing download request for: " $LOC_NAME | tee -a "$REQ_LOG_FILE"
					#echo  | tee -a "$REQ_LOG_FILE"
					echo "------------------------------" | tee -a "$REQ_LOG_FILE"
					echo "Here is last 3 lines from the associated log file:" | tee -a "$REQ_LOG_FILE"
					if ! tail -n 3 -q $LOG_FLD/$LOG_FILE | tee -a "$REQ_LOG_FILE" ; then
						echo "Error: Failed to read log file using the following command: 'tail -n 3 -q $LOG_FLD/$LOG_FILE'." | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
					fi
					echo "------------------------------" | tee -a "$REQ_LOG_FILE"
					#echo  | tee -a "$REQ_LOG_FILE"
				fi
				#change group assignment for just downloaded data
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Change group assignment to group '$GRP' for the created directory (and all its contents): '$FINAL_TRG_FLD'. Here is the command: chgrp -R $GRP $FINAL_TRG_FLD" | tee -a "$REQ_LOG_FILE"
				# echo "$(date +"%Y-%m-%d %H:%M:%S")-->Below is an output from change group command => chgrp -R -v $GRP $FINAL_TRG_FLD:" | tee -a "$REQ_LOG_FILE"
				chgrp -R $GRP $FINAL_TRG_FLD 2>&1 | tee -a "$REQ_LOG_FILE" # -v 
				#echo "------------------------------" | tee -a "$REQ_LOG_FILE"
			else
				if [ "$_PD" == "1" ]; then #output in debug mode only
					echo "$(date +"%Y-%m-%d %H:%M:%S")-->ERROR--> has occurred during processing download request for: " $LOC_NAME | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
					echo  | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
					echo "The log file for the failed download process: $LOG_FLD/$LOG_FILE" | tee -a "$REQ_ERROR_LOG_FILE" #output this only to error log file
					echo "------------------------------" | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
					echo "Here is last 10 lines from the associated log file:" | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
					if ! tail -n 10 -q $LOG_FLD/$LOG_FILE | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"; then
						echo "Error: Failed to read log file using the following command: 'tail -n 10 -q $LOG_FLD/$LOG_FILE'." | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
					fi
					echo "------------------------------" | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
					echo  | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
				fi
			fi
			echo "End of processing download request for:'$LOC_NAME'. Additional details of the processed download can be found in the log file: $LOG_FLD/$LOG_FILE" | tee -a "$REQ_LOG_FILE"
			echo "==============================" | tee -a "$REQ_LOG_FILE"
			echo  | tee -a "$REQ_LOG_FILE"
		fi
		CNT=$((CNT+1))
	done < "$file"
	
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->End of processing file: " $file | tee -a "$REQ_LOG_FILE"
	fi

# exit 0 # for testing only 

	#moving file to a processed folder
	PROCESSED_FILE=$REQ_FOLDER/$PROCESSED_FLD/$(date +"%Y%m%d_%H%M%S")_$(basename $file)
	CUR_FILE_PATH=$file
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->Moving and renaming processed file: '"$CUR_FILE_PATH"' to '"$PROCESSED_FILE"'" | tee -a "$REQ_LOG_FILE" 
	fi
	mkdir -p "$REQ_FOLDER/$PROCESSED_FLD"
	mv $CUR_FILE_PATH $PROCESSED_FILE
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->Download Request file: '"$CUR_FILE_PATH"' was moved/renamed to '"$PROCESSED_FILE"'" | tee -a "$REQ_LOG_FILE"
	fi
	
	ATTCH_REQUESTS=$ATTCH_REQUESTS" --attach-type text/plain --attach $PROCESSED_FILE"
	PROC_REQS=$PROC_REQS" "$(basename $PROCESSED_FILE)";"
done

echo "$(date +"%Y-%m-%d %H:%M:%S")-->Archiving tool: Start archiving old log files => $ARCH_TOOL_LOC -d -f $MAIN_LOG -e $CREATED_LOG_FILES" | tee -a "$REQ_LOG_FILE"

#invoke archiving tool to archive old log files except the most recent created one
if $ARCH_TOOL_LOC -d -f $MAIN_LOG -e $CREATED_LOG_FILES 2>&1 | tee -a "$REQ_LOG_FILE"; then
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Archiving tool has successfully finished" | tee -a "$REQ_LOG_FILE"
else
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Archiving tool has finished with an error" | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
fi

#prepare an email parameters to send status of the process
subject="Subject: Summary of processing download request " #$PROCESSED_FILE
attch_req_log="--attach-type text/plain --attach $REQ_LOG_FILE"
if test -f "$REQ_ERROR_LOG_FILE"; then
	#errors reported
	attch_err_log="--attach-type text/plain --attach $REQ_ERROR_LOG_FILE"
	email_body="Download request(s) for '$PROC_REQS' was(were) completed with ERRORS. See attached '$(basename $REQ_ERROR_LOG_FILE)' for details."
else
	#no errors reported
	attch_err_log=""
	email_body="Download request(s) for '$PROC_REQS' was(were) SUCCESSFULLY COMPLETED, no errors were reported."
fi

#send email
echo "$(date +"%Y-%m-%d %H:%M:%S")-->Preparing to send status email."  | tee -a "$REQ_LOG_FILE"
echo "$(date +"%Y-%m-%d %H:%M:%S")-->smtp = "$smtp "; to_email = "$to_emails "; from_email = "$from_email | tee -a "$REQ_LOG_FILE"
#swaks --server "$smtp" --to "$to_emails" --from "$from_email" --header "$subject"  --add-header "MIME-Version: 1.0" --add-header "Content-Type: text/html" --body "$email_body" --attach-type text/html --attach "$file" --attach-type text/html --attach "$REQ_LOG_FILE" $error_log_path
if ! swaks --server $smtp --to $to_emails --from $from_email --header "$subject"  --add-header "MIME-Version: 1.0" --add-header "Content-Type: text/html" --body "$email_body" $ATTCH_REQUESTS $attch_req_log $attch_err_log | tail -n 4  | tee -a "$REQ_LOG_FILE" ; then
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Unexpected error occurred during sending status email." | tee -a "$REQ_LOG_FILE" "$REQ_ERROR_LOG_FILE"
fi
