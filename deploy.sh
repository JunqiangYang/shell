#!/bin/bash
#script dir
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
ENV=$1
OP=$2
function import(){
    if [[ -f  $CURRENT_DIR/.tmp_param.bak ]];then
        . $CURRENT_DIR/.tmp_param.bak
    else
        "The first,to execute checkout.sh,please!"
        exit 1
    fi
}
function check_space(){
if [[ "$CURRENT_DIR" != "$SCRIPT_DIR" ]];then
   if [[ ! -f $CURRENT_DIR/.singlespace ]];then
      echo "ERROR: the current script cann't be executed."
      echo "the first,please to execute the follow cmd for creating single space:"
      echo '. single_space.sh $project_name'
      exit 1
   fi
fi
}
function check_param(){
    if  [[  "$ENV"X == "-t"X  ]] || [[ "$ENV"X == "-f"X ]] || [[ "$ENV"X == "-p"X ]];then
         if [ "$ENV"X == "-t"X ];then
            . $CURRENT_DIR/test_env.config
         else
			if [ "$ENV"X == "-f"X ];then
        	    . $CURRENT_DIR/formal_env.config
			else
				. $CURRENT_DIR/pre_env.config
			fi
         fi
		 if [[ "$OP"X != "start"X ]] && [[ "$OP"X != "stop"X ]];then
			OP="default"
		 fi
		 import
    else
        echo "cmd: $0 [ -t | -f ]   [ start | stop ]"
        echo "please input right command"
        echo "example:"
        	echo "$0 -t  start // start test  "
        	echo "$0 -f  start // start  formal " 
         exit
   fi
}
function main_publish(){
	for ipport in $deploy_addrs
	do
		ip=`echo $ipport |awk -F ':' '{print $1}'`
		echo " $OP ..........$ip "
		if [ "$OP" == "default" ];then
			ssh ${deploy_username}@$ip "if [ -d $deploy_path/$SERVICE_NAME-$VERSION ];then cd  $deploy_path/$SERVICE_NAME-$VERSION;sh bin/stop.sh ;sh bin/start.sh >/dev/null 2>&1;fi"	
		else
			ssh ${deploy_username}@$ip "if [ -d $deploy_path/$SERVICE_NAME-$VERSION ];then cd $deploy_path/$SERVICE_NAME-$VERSION;sh bin/$OP.sh >/dev/null 2>&1 ;fi"
		fi
	done
}

function main(){
	check_space
	check_param
	main_publish >/dev/null
}
#running 
main
