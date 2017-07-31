#!/bin/bash
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
PAGESIZE=10
linenum=0
IFS=""
cat $SCRIPT_DIR/README.ME | while read -r value
do
	echo "$value"
	linenum=$(($linenum+1))
	val=$((${linenum}%${PAGESIZE}))
	if [[ $val -eq 0 ]];then
		(exec </dev/tty; read key)
	fi
done 
