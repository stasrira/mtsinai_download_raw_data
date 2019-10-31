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