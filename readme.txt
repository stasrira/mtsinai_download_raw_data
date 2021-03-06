======================================================
Application for 
	- retrieving information from remote web locations
	- copying information from a network location
=======================================================

This application runs a script that utilizes other tools. Description of all supporting tools is provided further in this document.

----------------------------------------------
Start up scripts/files
----------------------------------------------
Execution of the tool is designed to be started with one of the following script files that will trigger execution of other tools. More details
on each tool can be found further in the document.
Here are the scripts to be used to start the tool: 
	- start_processing_requests_auto_posted_only.sh - will process requests posted in the "auto_posted" directory.
	- start_processing_requests_manually_posted_only.sh - will process requests posted in the "manually_posted" directory.
	- start_processing_requests_all_sources.sh - will process requests posted in "auto_posted" and "manually_posted" directories.

----------------------------------------------
process_requests.sh
----------------------------------------------
The main application script is "process_requests.sh". This script drives whole process and make calls to any other required tool. 

The application is designed to read request files provided in a specific format and run Data Downloader (dl_raw_data.sh) tool 
for each entry in the request file. This Data Downloader is a wrapper around the standard "wget" tool. The expectation that all log files 
are being present in central request location. Path to the directory containing requests is passed through a command line parameter on the start 
of the "process_requests.sh". 

The Request file contains one download requests per line in the file. 
	- Files are expected to be in the Tab-delimited format. 
	- First column of an entry presents a source of the data being downloaded, 
	- The second column presents a local destination directory where data will be stored, 
	- The third column presents the name of the directory (that will be created in the destination directory) where all downloaded data will be put. 
	- The tool will strip any folder structure from the provided source and store the actual data in the destination folder.
	- If method of processing of request is not supplied, every entry will be evaluated to ideintify the right method to use:
		- If the source data entry (1st column's entry) starts with "http://" or "https://", wget tool will be use. 
		- For all other cases, a network copy command (rsync) will be used.
	- Upon completion of processing the request, it is being moved to a "processed" folder which is a subfolder being created in the directory storing all requests. 
		- Appropriate permission should be set to allow the application to create "processed" folder.
	- While moving a request file to "processed" folder, it being renamed by adding a date stamp to the beginning of its name and putting a status of processing of it. 
		- If no errors were reported, the status will be OK, if at least one error was reported, the status will be ERROR. Details of the process run can be retrieved from log files.
 
Example of the request file entries:
...............................................
Source	Destination	LocalName
https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/096_ATACseq_AS10_07990_2/	/ext_data/stas/ECHO/HIV/HI/PBMC/scrna-seq	AS10-07990_2_Test_20191213
https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD01119_DARPA/fastqs/077_ATACseq_DU19_01S0003542_2/	/ext_data/stas/ECHO/MRSA/DU/PBMC/scatacseq/fastqs	DU19-01S0003542_2_Test_20191213
...............................................

During running, Data Downloader creates log files. "logs" folder is a container for all log files. 
	- A separate subfolder starting with a date stamp and reflecting the name of the request will be created for each processed request file.
	- Each such sub-folder will contain 
		- one log file for the request being processed (having words "process_log" in its name) 
		- a separate log file for each "wget" call being made during processing. 

Upon completion of the processing a request, an email could be configured to be sent to a predefined email addresses with summary of processing results. 
Email addresses are currently being set as hardcoded parameters in the "process_requests.sh" script. 

Any parameters required to be set for processing downloads (that are not being passed as command line parameters) are being set in the beginning of the script through a set of variables.

Archiving of the historical log files.
	- Since created log files for "wget" calls can be of a big size all previously created log files are being compacted and archived with the "tar" tool.
	- The "process_log" files are being excluded from archiving due to relatively small size of the files.
	- Archiving is performed with the Log Archiver tool.


Here is help info for in-line argument usage for process_requests.sh:

arguments usage:
        [-v: report the version; if this argument is supplied, it aborts execution of the script]
        [-h: help; if this argument is supplied, it aborts execution of the script]
        [-d: debug version]
        [-f path to folder that will contain Download Request files (of predefined format); this is a required parameter
                Request files have to be a tab-delimited text files.
                Each row of the file contains one download request, where
                        - First argument provides URL to the data to be downloaded.
                        - Second argument specifies path to the location where downloaded data will be saved.
                        - Third argument specifies the folder name that will be created in the given path; all downloaded data will be save in this folder.]
        [-s: pattern that will be used to search for Download Request files in the given folder. '*.tsv' is a default value.]
        [-m: command that will be used to perfomr the download/copy process. If not provided, the data source for each entry in the request file will be analyzed to select the appropriate command.
                - expected values are 'wget' or 'cp'].
----------------------------------------------
start_processing_requests.sh
----------------------------------------------
Start_processing_requests.sh contains a commanline call of the process_requests.sh script. It contains all parameters required to be passed to the process_requests.sh and 
used to simplify calling of the process_requests.sh. If desired, this script can be easily replaced with a direct command line call of the process_requests.sh.

----------------------------------------------
Data Downloader - dl_raw_data.sh (current version 1.01)
----------------------------------------------
This tool is designed to collect all files from the provided source location, which can be a web or local network one..
The tool is a wrapper around wget utility that is used to retrieve files. 
The tool will recursively go through all sub-folders, get all files and download those to a location specified. 
If a destination contains a folder with the same name as the one that was requested to be created, the existing folder will be archived before overwriting. 
A tar file will be created; the file name will consist of the original folder name and the date stamp of the time of archiving. If archiving is successfule
the process will delete the original folder. After that the process will recreated the folder with required name and the new set of data will be downloaded into there.
If archiving process fails, the process won't continue and the new data won't be donwnloaded. This failure will be reported as an error.

Here is help info for in-line argument usage:
	[-v: report the version; if this argument is supplied, it aborts execution of the script]
	[-h: help; if this argument is supplied, it aborts execution of the script]
	[-d: debug version]
	[-t target path where to downloaded data will be saved, i.e. /ext_data/stas/ECHO/PM/scrna-seq]
	[-u URL of the source (where from data is being downloaded), i.e. https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot/
	[-c number of URL's directories (following the main URL part with domain) that should be ignored, i.e. in the URL example provided for '-u' argument, there are 2 directories
	[-m: command that will be used to perfomr the download/copy process.
                - If not provided, the data source (-u parameter) for each entry in the request file will be analyzed to select the appropriate command.
                - expected values are 'wget' or 'cp'].

Usage example: 
./dl_raw_data.sh -t /ext_data/stas/ECHO/PM/scrna-seq -u https://wangy33.u.hpc.mssm.edu/10X_Single_Cell_RNA/TD00986_DARAPPilot -c 2

----------------------------------------------
Log archiver - arch_logs.sh (current version 1.01)
----------------------------------------------
This tool is designed to loop through all created archives and tar all files in the folder that were not archived yet with an exception 
of file(s) listed as exclusion. The idea of this process is to archive all log files except the most recent created log file. 
Here is help info for in-line argument usage:
	[-v: report the version; if this argument is supplied, it aborts execution of the script]
	[-h: help; if this argument is supplied, it aborts execution of the script]
	[-d: debug version]
	[-f path to target folder that will be checked for files to be archived; this is a required parameter
	[-m map of the file names (using shell standards) to select files to be archived in the provided folder, i.e. *.log
	[-e semicolon separated list of files to be excluded from archiving; it will contain file(s) that qualify for the provided map, but have to be excluded, i.e. 20190815_104445.log:20190815_104435.log

