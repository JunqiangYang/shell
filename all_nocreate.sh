#!/bin/bash
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
ENV=$1
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
    if  [[  "$ENV"X != "-t"X  ]] && [[ "$ENV"X != "-f"X ]] && [[ "$ENV"X != "-p"X ]]  ;then
        echo "cmd: $0 [ -t | -f | -p ]   "
        echo "please input right command"
        echo "example:"
            echo "$0 -t  // test  "
            echo "$0 -f  // formal " 
            echo "$0 -p  // pre " 
         exit
   fi
}
function all_action(){
	# checkout project 
	echo "---------checkout project--------------"
	sh $SCRIPT_DIR/checkout.sh $ENV >/dev/null
	if [ $? -ne 0 ];then
		exit 1
	fi
	# package project 
	echo "---------package project--------------"
	sh $SCRIPT_DIR/pack.sh $ENV >/dev/null
    if [ $? -ne 0 ];then
        exit 1
    fi
	# publish project
	echo "---------publish project--------------"
	sh $SCRIPT_DIR/publish.sh $ENV >/dev/null
    if [ $? -ne 0 ];then
        exit 1
    fi
	# deploy project
    echo "---------deploy project--------------"
	sh $SCRIPT_DIR/deploy.sh $ENV >/dev/null
}

function main(){
	check_space
	check_param
	all_action
}

#running 
main
