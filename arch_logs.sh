#!/bin/bash
set -euo pipefail

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
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Folder to be archived ('-f' parameter) was not set, aborting process!"
	exit 1
fi

EXCL_ARR=(${FLS_EXCL//:/ })
if [ "$_PD" == "1" ]; then #output in debug mode only
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Log folder to be search for files to be archived (-f) = "$FOLDER
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->File name mapping of the files to be archived (-m) = "$SRCH_MAP
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Files to be excluded from archive (-e) = "$FLS_EXCL
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Exclude files list from (-e) parameter = "${EXCL_ARR[@]}
fi

#for filename in ./get_raw_data_ECHO_PM_scRNAseq_logs/*.*; do
#loop through all files (based on a map) in the given folder
FILES=$(find $FOLDER -name "$SRCH_MAP")
#echo "FILES =>" $FILES
#for FILE in $FOLDER/$SRCH_MAP
for FILE in $FILES
do
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->FILE PATH= " $FILE
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->FILE NAME= " $(basename $FILE)
	fi
	SKIP=0
	for EXL in ${EXCL_ARR[@]}
	do
		if [ "$_PD" == "1" ]; then #output in debug mode only
			echo "$(date +"%Y-%m-%d %H:%M:%S")-->FILE EXL = " $EXL
		fi
		#compare file names to see if it has to be excluded
		if [ "$(basename $FILE)" == "$(basename $EXL)" ]; then
			SKIP=1
			if [ "$_PD" == "1" ]; then #output in debug mode only
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->File will be excluded = "$FILE
			fi
			break
		fi
	done
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->SKIP ARCHIVING FLAG = "$SKIP
	fi

	if [ "$SKIP" == "0" ]; then
		#create tar file for the given file name and delete file after archiving
		if [ "$_PD" == "1" ]; then #output in debug mode only
			echo "$(date +"%Y-%m-%d %H:%M:%S")-->File to be archved = "$FILE
		fi
		tar -cvzf $FILE".tar" $FILE && rm -f $FILE
	fi

done

