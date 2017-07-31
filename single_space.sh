#!/bin/bash
CURRENT_DIR=`pwd`
SCRIPT_DIR="`which checkout.sh |awk -F ' ' '{print $1}'`"
SCRIPT_DIR=`dirname $SCRIPT_DIR|awk -F ' ' '{print $1}'`
PROJECT_NAME=$1
BASE_SVN="svn://10.160.29.168"
TEST_CONFIG="test_env.config"
FORMAL_CONFIG="formal_env.config"
PRE_CONFIG="pre_env.config"
IS_CONTINUE=0
function create_space(){
	if [ -d $CURRENT_DIR/$PROJECT_NAME ];then
		echo "ERROR: Please,to create new project space,beacause $CURRENT_DIR/$PROJECT_NAME is exist."
		echo "Please into $CURRENT_DIR/$PROJECT_NAME,if you don't need create new space."
		IS_CONTINUE=1
	else
		mkdir -p $CURRENT_DIR/$PROJECT_NAME
	    yes|cp $SCRIPT_DIR/$TEST_CONFIG $CURRENT_DIR/$PROJECT_NAME
	    yes|cp $SCRIPT_DIR/$FORMAL_CONFIG $CURRENT_DIR/$PROJECT_NAME
	    yes|cp $SCRIPT_DIR/$PRE_CONFIG $CURRENT_DIR/$PROJECT_NAME
	fi
}

function initEvnConfig(){
	prefix=`echo $PROJECT_NAME |awk -F '_' '{print $NF}'`
	subfix=`echo $PROJECT_NAME |awk -F '_' '{print $1}'`
	(( $subfix + 10)) >/dev/null 2>&1
	if [[ $? -eq 0 ]];then
		sed -i s@^svn_addr=.*@svn_addr=\"$BASE_SVN/tags/$prefix/$PROJECT_NAME\"@g $CURRENT_DIR/$PROJECT_NAME/$FORMAL_CONFIG 
	else
		sed -i s@^svn_addr=.*@svn_addr=\"$BASE_SVN/tags/$PROJECT_NAME/$PROJECT_NAME\"@g $CURRENT_DIR/$PROJECT_NAME/$FORMAL_CONFIG 
	fi
	sed -i s@^svn_addr=.*@svn_addr=\"$BASE_SVN/trunk/$PROJECT_NAME\"@g $CURRENT_DIR/$PROJECT_NAME/$TEST_CONFIG
}

function checkCommand(){
	if [[ "$0" != "-bash"  ]] || [[ -z $PROJECT_NAME ]];then
		echoHelp
		IS_CONTINUE=1	
	fi
}
function echoHelp(){
        echo 'Usage: . single_space.sh [ "$project_name" ]'
		echo 'Input right command ,please!'
        echo "Examples:"
        echo '. single_space.sh  "$project_name"'
}
function createFlag(){
	if [ ! -f $CURRENT_DIR/$PROJECT_NAME/.singlespace ];then
		touch $CURRENT_DIR/$PROJECT_NAME/.singlespace
	fi
}
function main(){
	checkCommand
	echo "start create single space"
	if [[ $IS_CONTINUE -eq 0 ]];then
		create_space
	    if [[ $IS_CONTINUE -eq 0 ]];then
			initEvnConfig
			createFlag
			cd $CURRENT_DIR/$PROJECT_NAME
		fi
	fi
	echo "end create single space"
}
#start
main
