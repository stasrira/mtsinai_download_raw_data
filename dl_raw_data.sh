#!/bin/bash
set -euo pipefail

# test call example:
# network folder
# ./test4.sh -d -t /home/stas/test_dir/dir_target -u /home/stas/test_dir/dir_source1 -b dir -m cp
# web folder
# ./test4.sh -d -t /home/stas/test_dir/dir_target -u http://www.home.com/stas/test_dir/dir_source1 -b dir -m wget
# network file
# ./test4.sh -d -t /home/stas/test_dir/dir_target -u /home/stas/test_dir/dir_source1/test1.txt -b dir -m cp
#web file
# ./test4.sh -d -t /home/stas/test_dir/dir_target -u http://www.home.com/stas/test_dir/dir_source1/test1.txt -b file -m wget

Backup_target_folder () { 
	#_cmd_tar=$1
	#_tar=$2
	#_tar_file_name=$3
	_arch_obj=$1 #full path to the object to be archived
	
	_tar_file_name="${_arch_obj}_archive_$(date +"%Y%m%d_%H%M%S").tar"
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Predefined tar file name is ${_tar_file_name}"
	_cmd_tar="tar -cvf ${_tar_file_name} --remove-files ${_arch_obj}"

	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Proceeding with archiving of '$_arch_obj'."
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Here is the archiving command to be executed: '$_cmd_tar'"
	if echo "$_cmd_tar" |bash; then
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->Existing entity (folder/file) '$_arch_obj' was successfully archived to '$_tar_file_name' and its original content was deleted."
		return 0
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S")-->ERROR: Archiving existing folder $_tar failed. Aborting the data retrieval process for the current requests entry."
		return 1
	fi
}

#version of the script
_VER_NUM=1.03
_VERSION="`basename ${0}` (version: $_VER_NUM)" 

#define main variables
#examlpe of command: wget -r -np -R "index.html*" -nc -nH --cut-dirs=2 -P /ext_data/stas/ECHO/PM/scrna-seq  https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot/
#_CMD_TMP1="cp -Rv {{source_url}} {{target_path}}"
_CMD_TMP1="rsync -rvh --copy-links {{source_url}} {{target_path}}"
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
		\n\t[-b identifies if source item is a directory of file. Expected values: 1) dir, 2) file. It is required for web resources, where this is not easily recognizable. This value will be ignored for local resource that will be checked for the type of the source item.
		\n\t[-m: command that will be used to perfomr the download/copy process.
		\n\t\t- If not provided, the data source (-u parameter) for each entry in the request file will be analyzed to select the appropriate command.
		\n\t\t- expected values are 1) 'wget' - for web resources or 2) 'cp' - for local resources (note: 'rsync' - is an actual command to be used for local resources.].
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
_SRC_OBJ_TYPE="dir"

#analyze received arguments
while getopts u:t:c:m:b:dvh o
do
    case "$o" in
	u) _URL="$OPTARG";;
	t) _TRG="$OPTARG";;
	d) _PD="1";;
	c) _CUT_DIR_NUM="$OPTARG";;
	m) _COPY_METHOD="$OPTARG";;
	b) _SRC_OBJ_TYPE="$OPTARG";;
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
	echo "$(date +"%Y-%m-%d %H:%M:%S")-->Report (-b): " $_SRC_OBJ_TYPE
fi

#verify if target dir exists and source location is a folder too -> back up the target dir in this case, so the source dir do not overwrite the target dir
echo "$(date +"%Y-%m-%d %H:%M:%S")-->Start checking if archiving is needed for any existing data."

if [ -d "$_TRG" ]; then # check if target dir is an exsiting directory
	# target directory is an existing dir
	if [[ "$_COPY_METHOD" == "cp" ]]; then
		# source files are picked up from a network (not from a web) location
		if [[ -d $_URL ]]; then # check if source is a directory
			# source of data is a directory; backup is needed
			_ARCH_OBJ="${_TRG}"
			# call function to backup target object
			Backup_target_folder $_ARCH_OBJ
			if [ $? == 1 ]; then # check returned value
				# back up operation has failed, exit execution
				exit 1
			fi
		else
			if [[ -f $_URL ]]; then # check if source is a file
				# source of data is a file
				# echo `basename ${_URL}`
				_ARCH_OBJ="${_TRG}/"`basename ${_URL}`
				# echo "_ARCH_OBJ = "$_ARCH_OBJ
				if [[ -f $_ARCH_OBJ ]]; then # check if target file exists
					# target file exists, backup is needed
					# call function to backup target object
					Backup_target_folder $_ARCH_OBJ
					if [ $? == 1 ]; then # check returned value
						# back up operation has failed, exit execution
						exit 1
					fi
				else
					echo $_ARCH_OBJ" is not an existing file "
				fi
			else
				# source of data does not exists (not dir or file)
				echo "$(date +"%Y-%m-%d %H:%M:%S")-->Requested data source to be copied does not exist. Aborting the data retrieval process for the current requests entry. "
				exit 1
			fi
		fi
	else
		if [[ "$_COPY_METHOD" == "wget" ]]; then
			# source files are picked up from a web location
			if [[ "$_SRC_OBJ_TYPE" == "dir" ]]; then
				# source of web data is a directory; backup is needed
				_ARCH_OBJ="${_TRG}"
				# call function to backup target object
				Backup_target_folder $_ARCH_OBJ
				if [ $? == 1 ]; then # check returned value
					# back up operation has failed, exit execution
					exit 1
				fi
			else
				if [[ "$_SRC_OBJ_TYPE" == "file" ]]; then
					# source of web data is a file
					_ARCH_OBJ="${_TRG}/"`basename ${_URL}`
					if [[ -f $_ARCH_OBJ ]]; then # check if target file exists
						# target file exists, backup is needed
						# call function to backup target object
						Backup_target_folder $_ARCH_OBJ
						if [ $? == 1 ]; then # check returned value
							# back up operation has failed, exit execution
							exit 1
						fi
					fi
				else
					# type of web source data was not recognized (not dir or file), exit execution
					echo "$(date +"%Y-%m-%d %H:%M:%S")-->Provided source type parameter (-b) '$_SRC_OBJ_TYPE' was not recognized. Aborting the data retrieval process for the current requests entry. "
					exit 1
				fi
			fi
		else
			# copy method is not recognized, exit execution
			echo "$(date +"%Y-%m-%d %H:%M:%S")-->Provided copy method parameter (-m) '$_COPY_METHOD' was not recognized. Aborting the data retrieval process for the current requests entry. "
			exit 1
		fi
	fi
fi

echo "$(date +"%Y-%m-%d %H:%M:%S")-->Archiving of existing data has completed."

echo "$(date +"%Y-%m-%d %H:%M:%S")-->Verifying and creating (if not present) the destination directory $_TRG."
#verify that target folder exists and create it if it is not there
mkdir -p "$_TRG"

#verify requested method to be used and set the _CMD_TMP accordingly
if [ "$_COPY_METHOD" == "cp" ]; then
	_CMD_TMP=$_CMD_TMP1
	if [[ -d $_URL ]]; then
		#if source is a directory, add trailing slash to make sure that only content of the source is being copied without the origial folder name
		_URL=$_URL/ 
	fi
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

