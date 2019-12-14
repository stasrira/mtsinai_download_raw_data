#!/bin/bash
set -euo pipefail

function print_error {
    read line file <<<$(caller)
    echo "An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" >&2
}

file="/ext_data/stas/config/data_transfer_requests/processed/20191102_015133_data_transfer_request.tsv"
REQ_LOG_FILE="/ext_data/stas/config/logs/20191101_153153_process_requests_logs/20191101_153153_request_log.txt"
REQ_ERROR_LOG_FILE="/ext_data/stas/config/logs/20191101_153153_process_requests_logs/20191101_153153_error_log.txt"

smtp="smtp.mssm.edu:25"
to_emails="stasrirak.ms@gmail.com,stas.rirak@mssm.edu"
from_email="stas.rirak@mssm.edu"
subject="Subject: Summary of processing download request "$file

attch_request="--attach-type text/plain --attach $file"
attch_req_log="--attach-type text/plain --attach $REQ_LOG_FILE"

if test -f "$REQ_ERROR_LOG_FILE"; then
	#errors reported
    attch_err_log="--attach-type text/plain --attach $REQ_ERROR_LOG_FILE"
	email_body="Download request (for '$(basename $file)') was completed with ERRORS. See attached '$(basename $REQ_ERROR_LOG_FILE)' for details."
else
	#no errors reported
	attch_err_log=""
	email_body="Download request (for '$(basename $file)') was SUCCESSFULLY completed, no errors were reported."
fi

#attch_err_log="$REQ_ERROR_LOG_FILE"
#send email
echo swaks --server "$smtp" --to "$to_emails" --from "$from_email" --header "$subject"  --add-header "MIME-Version: 1.0" --add-header "Content-Type: text/html" --body "$email_body" --attach-type text/html --attach "$file" --attach-type text/html --attach "$REQ_LOG_FILE" $attch_err_log
#swaks --server "$smtp" --to "$to_emails" --from "$from_email" --header "$subject"  --add-header "MIME-Version: 1.0" --add-header "Content-Type: text/html" --body "$email_body" --attach-type text/html --attach "$file" --attach-type text/html --attach "$REQ_LOG_FILE" $attch_err_log
if ! swaks --server "$smtp" --to "$to_emails" --from "$from_email" --header "$subject"  --add-header "MIME-Version: 1.0" --add-header "Content-Type: text/html" --body "$email_body" $attch_request $attch_req_log $attch_err_log | tail -n 4; then
	echo "Unexpected error occurred during sending status email." 
fi

echo "After Email sending"

exit 0


#version of the script
_VER_NUM=1.01
_VERSION="`basename ${0}` (version: $_VER_NUM)" 

FOLDER="" #"./get_raw_data_ECHO_PM_scRNAseq_logs"
SRCH_MAP="*.log"
FLS_EXCL="" #"20190815_104445.log:20190815_104435.log:20190815_104320.log"

_PD=0

_HELP="\n$_VERSION
	\n\narguments usage: 
		\n\t[-v: report the version; if this argument is supplied, it aborts execution of the script]
		\n\t[-h: help; if this argument is supplied, it aborts execution of the script]
		\n\t[-d: debug version]
		\n\t[-f path to target folder that will be checked for files to be archived; this is a requied parameter
		\n\t[-m map of the file names (using shell standards) to select files to be archived in the provided folder, i.e. *.log
		\n\t[-e semicolon separated list of files to be excluded from archiving; it will contain file(s) that qualify for the provided map, but have to be excluded, i.e. 20190815_104445.log:20190815_104435.log
		"

#analyze received arguments
while getopts f:m:e:dvh o
do
    case "$o" in
	f) FOLDER="$OPTARG";;
	m) SRCH_MAP="$OPTARG";;
	e) FLS_EXCL="$OPTARG";;
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

if [ "$FOLDER" == "" ]; then
	#if folder parameter was not provided, abourt the operation
	echo "Folder to be archived ('-f' parameter) was not set, aborting process!"
	exit 1
fi

EXCL_ARR=(${FLS_EXCL//:/ })
if [ "$_PD" == "1" ]; then #output in debug mode only
	echo "Log folder to be search for files to be archived (-f) = "$FOLDER
	echo "File name mapping of the files to be archived (-m) = "$SRCH_MAP
	echo "Files to be excluded from archive (-e) = "$FLS_EXCL
	echo "Exclude files list from (-e) parameter = "${EXCL_ARR[@]}
fi

#for filename in ./get_raw_data_ECHO_PM_scRNAseq_logs/*.*; do
#loop through all files (based on a map) in the given folder
FILES=$(find $FOLDER -name "$SRCH_MAP")
#echo "FILES =>" $FILES
#for FILE in $FOLDER/$SRCH_MAP
for FILE in $FILES
do
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "FILE PATH= " $FILE
		echo "FILE NAME= " $(basename $FILE)
	fi
	SKIP=0
	for EXL in ${EXCL_ARR[@]}
	do
		if [ "$_PD" == "1" ]; then #output in debug mode only
			echo "FILE EXL = " $EXL
		fi
		#compare file names to see if it has to be excluded
		if [ "$(basename $FILE)" == "$(basename $EXL)" ]; then
			SKIP=1
			if [ "$_PD" == "1" ]; then #output in debug mode only
				echo "File will be excluded = "$FILE
			fi
			break
		fi
	done
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "SKIP ARCHIVING FLAG = "$SKIP
	fi

	if [ "$SKIP" == "0" ]; then
		#create tar file for the given file name and delete file after archiving
		if [ "$_PD" == "1" ]; then #output in debug mode only
			echo "File to be archved = "$FILE
		fi
		#tar -cvzf $FILE".tar" $FILE && rm -f $FILE
	fi

done




exit 0

#test adding entries to a log file
#identify locations and names of log_folder for this run
MAIN_LOG="logs"
ME=$(echo "${0##*/}" | cut -f 1 -d '.') #get name of the file it is running from
LOG_FLD=$MAIN_LOG/$(date +"%Y%m%d_%H%M%S")_$ME"_logs"
REQ_LOG_FILE=$LOG_FLD/$(date +"%Y%m%d_%H%M%S")"_request.log"

mkdir -p $LOG_FLD

echo $REQ_LOG_FILE
echo "$(date +"%Y-%m-%d %H:%M:%S")-->Log entry #1" | tee -a $REQ_LOG_FILE
echo "$(date +"%Y-%m-%d %H:%M:%S")-->Log entry #2" | tee -a $REQ_LOG_FILE




exit 0

#moving file to a processed folder
REC_FOLDER="data_transfers_requests"
PROCESSED_FLD="processed"
file="data_transfer_request.tsv"
_PD=1

PROCESSED_FILE=$REC_FOLDER/$PROCESSED_FLD/$(date +"%Y%m%d_%H%M%S")_$(basename $file)
CUR_FILE_PATH=$REC_FOLDER/$file
if [ "$_PD" == "1" ]; then #output in debug mode only
	echo "Moving and renaming processed file: '"$CUR_FILE_PATH"' to '"$PROCESSED_FILE"'" 
fi
mkdir -p "$REC_FOLDER/$PROCESSED_FLD"
mv $CUR_FILE_PATH $PROCESSED_FILE



exit 0

ARCH_TOOL_LOC="./arch_logs.sh"
MAIN_LOG="logs"
LOG_FLD="test_logs_no_archive"

$ARCH_TOOL_LOC -d -f $MAIN_LOG -e $LOG_FLD

exit 0

IN="https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/096_ATACseq_AS10_07990_2/"

elements=$(echo $IN | tr "/" "\n")
echo ${#elements[@]}
cnt=0
for el in $elements
do
    cnt=$((cnt+1))
	echo "--> $el"
done
echo $cnt
echo Total: $cnt
echo Cut_num: $((cnt-2))

exit 0

IFS='/'

read -ra PARTS <<< "$IN"
len=${PARTS[@]}
echo $len
#echo PARTS lenght = "${PARTS[@]}"
echo Sections num = ${PARTS[@]}-2
for i in "${PARTS[@]}"; do # access each element of array
    echo "$i"
done
IFS=' '