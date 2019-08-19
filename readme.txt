======================================================
Tools for retrieving RawData from remote web locations
=======================================================

----------------------------------------------
Tool #1 - Raw Data Downloader - dl_raw_data.sh (current version 1.01)
----------------------------------------------
This tool is designed to collect all files from the provided web location (except html files).
The tool is a wrapper around wget utility that is used to retrieve files. 
The main purpose is to collect sequencing result files (fastq, etc.) It will recursively go through all sub-folders, 
get all files and download those to a location specified. The tool will not take files that were already downloaded and 
exist in the destination location.
The tool always won't create a sub-folder in the destination location corresponding the domain name of the URL being a source. 
The tool (by default) will create a sub-folder structure corresponding to the URL's route structure following the domain name. However,
there is an ability to avoid that using [-c] argument.

Here is help info for in-line argument usage:
	[-v: report the version; if this argument is supplied, it aborts execution of the script]
	[-h: help; if this argument is supplied, it aborts execution of the script]
	[-d: debug version]
	[-t target path where to downloaded data will be saved, i.e. /ext_data/stas/ECHO/PM/scrna-seq]
	[-u URL of the source (where from data is being downloaded), i.e. https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot/
	[-c number of URL's directories (following the main URL part with domain) that should be ignored, i.e. in the URL example provided for '-u' argument, there are 2 directories

Usage example: 
./dl_raw_data.sh -t /ext_data/stas/ECHO/PM/scrna-seq -u https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot -c 2

----------------------------------------------
Tool #2 - Log archiver - arch_logs.sh (current version 1.01)
----------------------------------------------
This tool is designed to loop through all created archives and tar all files in the folder that were not archived yet with an exception 
of file(s) listed as exclusion. The idea of this process is to archive all log files except the most recent created log file. 
Here is help info for in-line argument usage:
	[-v: report the version; if this argument is supplied, it aborts execution of the script]
	[-h: help; if this argument is supplied, it aborts execution of the script]
	[-d: debug version]
	[-f path to target folder that will be checked for files to be archived; this is a requied parameter
	[-m map of the file names (using shell standards) to select files to be archived in the provided folder, i.e. *.log
	[-e semicolon separated list of files to be excluded from archiving; it will contain file(s) that qualify for the provided map, but have to be excluded, i.e. 20190815_104445.log:20190815_104435.log

----------------------------------------------
Get Raw Data scripts - i.e. get_raw_data_ECHO_HLTH_DU_PBMC_scRNAseq_prod.sh
----------------------------------------------
Each Get Raw Data scripts is designed to be a config file storing main properties of the process and responsible for the collecting 
data feed from one web location to one local destination. One such script will be required for each required data feed.
The script will create a log file for each execution event storing all standard and error output from execution of all commands.
Log files will be created in the folder named as the name of the script with addition of "_logs" postfix at the end of the name. 
Each script stores the following configuration parameters (values below are provided as an example and have to be adjusted for each file). 
These parameters have to be adjusted for each data feed.
	DL_TOOL_LOC="./dl_raw_data.sh" #identifies path to the raw data download tool
	ARCH_TOOL_LOC="./arch_logs.sh" #identifies path to the log archiver tool
	DLD_URL="https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00814_TechDev_Duke_collab/" #remote web folder where from data is picked up
	TRG_FLD="/ext_data/shared/ECHO/HLTH/DU/PBMC/scrna-seq" #local folder where to data is being downloaded

----------------------------------------------
Automation of the process.
----------------------------------------------
Script run_raw_data.sh is designed to be a single start point to run all "get_raw_data..." scripts present in the folder. 
Running this script essentially the same as running all those scripts one by one.
TODO: schedule running this script automatically from a scheduler.

Arguments usage:
        [-h: help; if this argument is supplied, it aborts execution of the script]
        [-d: debug version, display addtional information and argument values]
        [-n: no run flag, should be used together with debug argument (-d) to display files to be run without actual execution of the files]
        [-f path to target folder, default value is the script's current location]
        [-m map of the file names (using shell standards) to select files to be executed, defaut value: get_raw_data*.sh]

