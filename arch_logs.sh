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
	echo "Folder to be archived ('-f' parameter) was not set, aborting process!"
	exit 1
fi

EXCL_ARR=(${FLS_EXCL//:/ })
if [ "$_PD" == "1" ]; then #output in debug mode only
	echo "Exclude flies list = "${EXCL_ARR[@]}
fi

#for filename in ./get_raw_data_ECHO_PM_scRNAseq_logs/*.*; do
#loop through all files (based on a map) in the given folder
FILES=$(find $FOLDER -name "$SRCH_MAP")
#for FILE in $FOLDER/$SRCH_MAP
for FILE in $FILES
do
	SKIP=0
	for EXL in ${EXCL_ARR[@]}
	do
		#echo "Variable EXL = " $EXL
		if [ "$FILE" == "$FOLDER/$EXL" ]; then
			SKIP=1
			if [ "$_PD" == "1" ]; then #output in debug mode only
				echo "File is excluded = "$FILE
			fi
			break
		fi
	done
	#echo "Variable SKIP = "$SKIP
	
	if [ "$SKIP" == 0 ]; then
		#create tar file for the given file name and delete file after archiving
		if [ "$_PD" == "1" ]; then #output in debug mode only
			echo "File to be archved = "$FILE
		fi
		tar -cvf $FILE".tar" $FILE && rm -f $FILE
	fi

done

