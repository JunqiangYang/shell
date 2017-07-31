#!/bin/bash
#script dir
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
PROJECT_NAME=default
SERVICE_NAME=default
VERSION=default
TOOL_DIR=default
IS_SINGLE_WORKSPANCE=0
ENV=$1
TAG_VERSION=$2
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
function servicename(){
    SERVICE_NAME=`find  $TOOL_DIR/$PROJECT_NAME/src  -name AppMain.java -type f|sed s@/main/AppMain.java@@g`
	SERVICE_NAME=`basename $SERVICE_NAME`
}
function version(){
	 VERSION=`cat $TOOL_DIR/$PROJECT_NAME/pom.xml|grep -A6 "<artifactId>$SERVICE_NAME</artifactId>"|grep -m 1 'version'|awk -F "[><]" '{print $3}'`
	if [ -z $VERSION ];then
	   VERSION=`date +%Y%m%d`
	fi
    VERSION=$VERSION".dy"
}
function check_param(){
	case $ENV  in
		-t)
			. $CURRENT_DIR/test_env.config
			env=0
		;;
		-ts|-st)
			 . $CURRENT_DIR/test_env.config
			 env=0
			IS_SINGLE_WORKSPANCE=1
		;;
		-f)
			. $CURRENT_DIR/formal_env.config
			env=1
		;;
		-fs|-sf)
			. $CURRENT_DIR/formal_env.config
			env=1
			IS_SINGLE_WORKSPANCE=1
		;;
	   -p)
            . $CURRENT_DIR/pre_env.config
            env=1
        ;;
        -ps|-sp)
            . $CURRENT_DIR/pre_env.config
            env=1
            IS_SINGLE_WORKSPANCE=1
        ;;
		*)
        	echo 'cmd: $0 [ -t | -f | -p | -ts | -fs  | -ps ] [ "$tag_version" ]'
        	echo 'please input right command'
        	echo "example:"
            	echo $0 '-t  "$tag_version" //test env '
            	echo $0 '-f  "$tag_version" //formal env '
            	echo $0 '-p  "$tag_version" //pre env '
				echo $0 '-ts  "$tag_version" //test env and single workspace'
				echo $0 '-fs  "$tag_version" //formal env and single workspace'
				echo $0 '-ps  "$tag_version" //pre env and single workspace'
        	exit
	esac			
}

function project_name(){
  	PROJECT_NAME=`basename $svn_addr`
	if [ -z $PROJECT_NAME ];then
		 PROJECT_NAME=default
	fi
	TAG_V=`echo $TAG_VERSION |grep -E ^[0-9a-zA-Z]`
	if [ "$TAG_V"X == ""X ];then
		PROJECT_NAME=${PROJECT_NAME}${TAG_VERSION}
	else
		PROJECT_NAME=${PROJECT_NAME}_${TAG_VERSION}
	fi
}
function svn_checkout(){
	url_=`dirname $svn_addr`
	url_=${url_}/${PROJECT_NAME}
	TOOL_DIR="$CURRENT_DIR"
	isContain=$(echo $CURRENT_DIR|grep "${PROJECT_NAME}_tool")
	if [ ! $isContain ] && [ $IS_SINGLE_WORKSPANCE -eq 1 ];then
		tmp_flag="0"
		ls $CURRENT_DIR |while read value
		do
			if [  "$value"X == "${PROJECT_NAME}_tool"X ];then
				tmp_flag=""
				break
			fi
		done
		if [ $tmp_flag ];then
			mkdir -p $TOOL_DIR/${PROJECT_NAME}_tool
            TOOL_DIR=$TOOL_DIR/${PROJECT_NAME}_tool;
		fi
	fi
	if [ -d $TOOL_DIR/$PROJECT_NAME ];then
		rm -rf $TOOL_DIR/$PROJECT_NAME
	fi
	export LC_ALL="en_US.UTF-8";svn --no-auth-cache --non-interactive --trust-server-cert --username deploy --password deployny checkout $url_  $TOOL_DIR/$PROJECT_NAME >&2 
#	if [ "$TOOL_DIR"X != "$CURRENT_DIR"X ];then
#		ls $SCRIPT_DIR|while read value
#  		do
#			isContain=$(echo $value|grep ^create )
#			if [[ -f $value ]] && [[ ! $isContain ]];then
#				cp $SCRIPT_DIR/$value $TOOL_DIR
#			fi
#		done	
#	fi
}
function bak_param(){
  servicename
  version
  echo "PROJECT_NAME=$PROJECT_NAME" >$TOOL_DIR/.tmp_param.bak
  echo "SERVICE_NAME=$SERVICE_NAME" >>$TOOL_DIR/.tmp_param.bak
  echo "VERSION=$VERSION" >>$TOOL_DIR/.tmp_param.bak
}
function del_deploypackage(){
    if [ -d $TOOL_DIR/$PROJECT_NAME-$VERSION ];then
        rm -rf $TOOL_DIR/$PROJECT_NAME-$VERSION
    fi
}
function main(){
	echo "start checkout ......"
	check_space
	check_param
	project_name  >/dev/null
	svn_checkout  >/dev/null
	bak_param   >/dev/null
	del_deploypackage >/dev/null
}

#start

#running
main


