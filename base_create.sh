#!/bin/bash
#script dir
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
SVN_TRUNK="svn://10.160.29.168/trunk"
TMP_DIR="$CURRENT_DIR/.tmp_create"
PROJECT_DIR=$TMP_DIR
TEMPLATE_NAME="app_service_template"
ISMVNPRO=$1
PROJECT_NAME=$2
USERNAME=$3
PASSWORD=$4
MVNSRC="src/main/java"
MVNSRCRESOURCES="src/main/resources"
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
	if [ ! -z $PROJECT_NAME ];then
		if [ -z $USERNAME ];then
			PROJECT_DIR=$CURRENT_DIR
		fi
		if [ "$ISMVNPRO" != "1" ];then
			ISMVNPRO=0
		fi	
	else
		echo cmd: $0 '[ $project_name ] [ $svn_username ] [ $svn_password ]'
		echo example:
		echo "	$0 appservcie alei  1q2w3e "
		echo '	notice: input $svn_username/$svn_password,the current project will be submit to svn'
		exit 1
	fi
}

function checkout_template(){
	if [ ! -d $TMP_DIR ];then
		mkdir -p $TMP_DIR
	else
		if [ "$TMP_DIR"  ==  "$CURRENT_DIR/.tmp_create" ];then
			rm -rf $TMP_DIR
		fi
	fi
    export LC_ALL="en_US.UTF-8";svn --no-auth-cache --non-interactive --trust-server-cert --username deploy --password deployny  checkout $SVN_TRUNK/$TEMPLATE_NAME  $TMP_DIR/$TEMPLATE_NAME
}
function check_project(){
	num=` svn --no-auth-cache --non-interactive --trust-server-cert --username deploy --password deployny list --verbose  $SVN_TRUNK |awk -F ' ' '{print $6}' |awk -F '/' '{print $1}'|grep -e "^$PROJECT_NAME$" -c `
	if [ "$num"X != "0"X ];then
		echo  $PROJECT_NAME is  exist on svn,please change it.
		exit
	fi
}
function create_project(){
	if [ ! -d $PROJECT_DIR/$PROJECT_NAME ];then
		mkdir -p $PROJECT_DIR/$PROJECT_NAME
	fi
	cp -rd $TMP_DIR/$TEMPLATE_NAME/* $PROJECT_DIR/$PROJECT_NAME
	JAVASRC=$PROJECT_DIR/$PROJECT_NAME/src
	JAVARESOURCE=$PROJECT_DIR/$PROJECT_NAME/src
	if [ "$ISMVNPRO" == "1" ];then
		if [ ! -d "$PROJECT_DIR/$PROJECT_NAME/$MVNSRCRESOURCES" ];then
	  		mkdir -p $PROJECT_DIR/$PROJECT_NAME/$MVNSRCRESOURCES
			ls $JAVASRC/|while read val
    		do
				if [ -f $JAVASRC/$val ];then
					mv $JAVASRC/$val $PROJECT_DIR/$PROJECT_NAME/$MVNSRCRESOURCES/
				fi
    		done	
           JAVARESOURCE=$PROJECT_DIR/$PROJECT_NAME/$MVNSRCRESOURCES
        fi
		if [ ! -d "$PROJECT_DIR/$PROJECT_NAME/$MVNSRC" ];then
			mkdir -p $PROJECT_DIR/$PROJECT_NAME/$MVNSRC
			ls $JAVASRC/ |while read val
			do
				if [[ "$MVNSRC" =~ "/$val" ]]||[[ "$MVNSRCRESOURCES" =~ "/$val" ]];then
					 continue
			 	fi
				mv $JAVASRC/$val $PROJECT_DIR/$PROJECT_NAME/$MVNSRC/
			done
			JAVASRC=$PROJECT_DIR/$PROJECT_NAME/$MVNSRC
		fi	
	fi	
	dir_=`find  $PROJECT_DIR/$PROJECT_NAME -type d |grep -e $TEMPLATE_NAME$`
    p_path_=`dirname $dir_`
	mv $dir_  $p_path_/$PROJECT_NAME
	find $PROJECT_DIR/$PROJECT_NAME -name $TEMPLATE_NAME.config -type f|while read path
	do
		dir=`dirname $path`
   		mv $path  $dir/$PROJECT_NAME.config
	done
	find $PROJECT_DIR/$PROJECT_NAME |grep  '\/\.svn' |while read value
	do
		if [[ -d $value ]] || [[ -f $value ]];then
			rm -rf $value
		fi	
	done	
	find $PROJECT_DIR/$PROJECT_NAME/sbin/* -type d  |while read value
	do
			rm -rf $value
	done
	find $PROJECT_DIR/$PROJECT_NAME -type f |grep -v "\.jar$" |while read value
    do
		sed -i "s@$TEMPLATE_NAME@$PROJECT_NAME@g" $value
		echo $value|grep -e "\.rpc$"|while read val
		do
			sed -i "s@^dubbo.name=.*@dubbo.name=$PROJECT_NAME@g" $value
			if [ ! -z "$USERNAME" ];then
				sed -i "s@^dubbo.owner=.*@dubbo.owner=$USERNAME@" $value
			fi
		done
    done	
}
function sync_svn(){
	if [ "$PROJECT_DIR"X != "$CURRENT_DIR"X ];then	
		if [ -z  "$PASSWORD" ];then
			PASSWORD=DEFAULT
		fi
		svn --no-auth-cache --non-interactive --trust-server-cert --username $USERNAME --password $PASSWORD import $PROJECT_DIR/$PROJECT_NAME  $SVN_TRUNK/$PROJECT_NAME -m "create $PROJECT_NAME"
		flag=$?
		rm -rf $TMP_DIR
		if [ "$flag" != "0" ];then
			exit
		fi
	fi
}

function change_config(){
	find  $CURRENT_DIR  -maxdepth 1 -type f |grep -e '\.config' |while read config
	do
		sed -i s@^svn_addr=.*@svn_addr=\"$SVN_TRUNK/$PROJECT_NAME\"@g $config 
	done
}
function main(){
	check_space
	check_param
	check_project		
	checkout_template >/dev/null
	create_project >/dev/null
	sync_svn  >/dev/null
	change_config >/dev/null
}
#running
main
