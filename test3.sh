#!/bin/bash
echo "pwd: `pwd`"
echo "\$0: $0"
echo "basename: `basename $0`"
echo "dirname: `dirname $0`"
echo "dirname/readlink: $(dirname $(readlink -f $0))"

dir=`dirname $0`
echo "dir variable = "$dir

wrk_dir=`dirname $0`
DL_TOOL_LOC=$wrk_dir"/dl_raw_data.sh" #path to the download tool
ARCH_TOOL_LOC=$wrk_dir"/arch_logs.sh"

echo $DL_TOOL_LOC
echo $ARCH_TOOL_LOC