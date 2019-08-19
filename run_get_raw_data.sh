#!/bin/bash
set -euo pipefail

FOLDER="./" #current folder is default folder location
SRCH_MAP="get_raw_data*.sh" #map of the file names to be used for automated execution

_PD=0
_NORUN=0

_HELP="Arguments usage: 
		\n\t[-h: help; if this argument is supplied, it aborts execution of the script]
		\n\t[-d: debug version, display addtional information and argument values]
		\n\t[-n: no run flag, should be used together with debug argument (-d) to display files to be run without actual execution of the files]
		\n\t[-f path to target folder, default value is the script's current location]
		\n\t[-m map of the file names (using shell standards) to select files to be executed, defaut value: get_raw_data*.sh]
		"

#analyze received arguments
while getopts f:m:ndvh o
do
    case "$o" in
	f) FOLDER="$OPTARG";;
	m) SRCH_MAP="$OPTARG";;
	d) _PD="1";;
	n) _NORUN="1";;
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
	echo "Folder to be search for files to be executed = "$FOLDER
	echo "File name mapping of the files to be executed = "$SRCH_MAP  
fi

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
if [ "$_PD" == "1" ]; then #output in debug mode only
	echo "Current working directory = "$SCRIPTPATH
fi
#for filename in ./get_raw_data_ECHO_PM_scRNAseq_logs/*.*; do
#loop through all files (based on a map) in the given folder
FILES=$(find $FOLDER -name "$SRCH_MAP")
#for FILE in $FOLDER/$SRCH_MAP
for FILE in $FILES
do
	#execute files one by one
	if [ "$_PD" == "1" ]; then #output in debug mode only
		echo "File to be executed = "$FILE
		echo "NORUN argument [-n] = "$_NORUN
	fi
	if [ "$_NORUN" != "1" ]; then #run the file
		$FILE
	else
		echo "File '$FILE' was not run due to set value of NORUN argument [-n] = 1"
	fi
done

