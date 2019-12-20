#!/bin/bash
set -euo pipefail

#version of the script
_VER_NUM=1.02
_VERSION="`basename ${0}` (version: $_VER_NUM)" 

#define main variables
#examlpe of command: wget -r -np -R "index.html*" -nc -nH --cut-dirs=2 -P /ext_data/stas/ECHO/PM/scrna-seq  https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot/
#_CMD_TMP1="cp -Rv {{source_url}} {{target_path}}"
_CMD_TMP1="rsync -rvh {{source_url}} {{target_path}}"
_CMD_TMP2="wget -r -np -R \"index.html*\" -nc -nH --cut-dirs={{cut_dir_num}} -P {{target_path}} {{source_url}}"
_CMD_TMP=""
_PL_HLDR_URL="{{source_url}}"
_PL_HLDR_TRG="{{target_path}}"
_PL_HLDR_CUT_DIR_NUM="{{cut_dir_num}}"
#_PL_HLDR_LOC_NAME="{{local_name}}"

_HELP="\n$_VERSION
	\n\narguments usage: 
		\n\t[-v: report the version; if this argument is supplied, it aborts execution of the script]
		\n\t[-h: help; if this argument is supplied, it aborts execution of the script]
		\n\t[-d: debug version]
		\n\t[-t target path where to downloaded data will be saved, i.e. /ext_data/stas/ECHO/PM/scrna-seq] 
		\n\t[-u URL of the source (where from data is being downloaded), i.e. https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot/
		\n\t[-c number of URL's directories (following the main URL part with domain) that should be ignored, i.e. in the URL example provided for '-u' argument, there are 2 directories
		\n\t[-m: command that will be used to perfomr the download/copy process. 
		\n\t\t- If not provided, the data source (-u parameter) for each entry in the request file will be analyzed to select the appropriate command.
		\n\t\t- expected values are 'wget' or 'cp'].
		"

#set default values
#_PR="studystats"	#default value for query name
#_PI="1"				#default value for id
#_PF="" 				#default value for a format argument; 
#_PS=","				#default separator for a delimited format;

#TODO: set target_path to current folder 
_TRG=""

_PD=""
_URL=""
_CUT_DIR_NUM=0
_COPY_METHOD=""

#analyze received arguments
while getopts u:t:c:m:dvh o
do
    case "$o" in
	u) _URL="$OPTARG";;
	t) _TRG="$OPTARG";;
	d) _PD="1";;
	c) _CUT_DIR_NUM="$OPTARG";;
	m) _COPY_METHOD="$OPTARG";;
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

#output values of arguments in debug mode
if [ "$_PD" == "1" ]; then #output in debug mode only
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Report (-u): " $_URL
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Report (-t): " $_TRG
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Report (-c): " $_CUT_DIR_NUM
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Report (-m): " $_COPY_METHOD
fi

#verify that target folder exists and back it up if it exists
_TAR_FILE_NAME="${_TRG}_$(date +"%Y%m%d_%H%M%S").tar"
echo "$(date +"%Y-%m-%d %H:%M:%S")-->Predefined tar file name, in case a backup is needed, is ${_TAR_FILE_NAME}"
CMD_TAR="tar -cvf ${_TAR_FILE_NAME} --remove-files ${_TRG}"
if [ -d "$_TRG" ]; then
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Here is the archiving command to be executed: '$CMD_TAR'"
	#if tar -cvf ${_TAR_FILE_NAME} --remove-files ${_TRG}; then
	if echo "$CMD_TAR" |bash; then
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->Existing folder $_TRG was successfully archived to $_TAR_FILE_NAME and its original content was deleted."
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->ERROR: Archiving existing folder $_TRG failed. Aborting the data retrieval process for the current requests entry."
		exit 1
	fi
fi

#verify that target folder exists and create it if it is not there
mkdir -p "$_TRG"

#verify requested method to be used and set the _CMD_TMP accordingly
if [ "$_COPY_METHOD" == "cp" ]; then
	_CMD_TMP=$_CMD_TMP1
	_URL=$_URL/ #adds trailing slash to make sure that only content of the source is being copied without the origial folder name
fi
if [ "$_COPY_METHOD" == "wget" ]; then
	_CMD_TMP=$_CMD_TMP2
fi

if [ "$_PD" == "1" ]; then #output in debug mode only
    echo "$(date +"%Y-%m-%d %H:%M:%S")-->Command template(_CMD_TMP): " $_CMD_TMP
fi

#update _CMD_TMP variable by substituting place-holders with the actual values supplied as an argument
_CMD=${_CMD_TMP//$_PL_HLDR_URL/$_URL}
_CMD=${_CMD//$_PL_HLDR_TRG/$_TRG}
_CMD=${_CMD//$_PL_HLDR_CUT_DIR_NUM/$_CUT_DIR_NUM}
#_CMD=${_CMD//$_PL_HLDR_LOC_NAME/$_LOC_NAME}

#combine the full sqlcmd call into a string; actual SQL query is delimited with double quotes (presented as escap characters)
#_CMD="sqlcmd -S $_S -U $_U -P $_P -d $_D -Q \" $_QR \" $_DELIM_FMT"

if [ "$_PD" == "1" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S")-->Final Command to be executed: '$_CMD'"
fi
echo "${_CMD}" |bash #execute preapred command
if [ "$_PD" == "1" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S")-->Finish execution of the final command."
fi

