#!/bin/bash
#script dir
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
ENV=$1
CMD=$2
IP=$3
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
    if  [[  "$ENV"X == "-t"X  ]] || [[ "$ENV"X == "-f"X ]] ;then
         if [ "$ENV"X == "-t"X ];then
            . $SCRIPT_DIR/test_env.config
         else
            . $SCRIPT_DIR/formal_env.config
         fi
 
    else
        echo ' cmd: $0 [ -t | -f ]  [ $cmd ] [ $ip ] '
        echo "please input right command"
        echo "example:"
            echo "$0" ' -t  $cmd  //cmd test  '
            echo "$0" ' -f  $cmd  //cmd formal '
         exit
   fi
}

function cmd(){
	if [ ! -z $IP ];then
		echo "----------$IP--------"
		ssh $IP " $CMD "
	else
		for ip in $deploy_addrs
		do
			echo "-----------$ip---------"
			ssh ${deploy_username}@$ip " $CMD "
		done
	fi
}

function main(){
	check_space
	check_param
	cmd
}
$run
main
