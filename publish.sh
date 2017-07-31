#!/bin/bash
#script dir
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
ENV=$1
USERNAME="nyuser"
WAITTIME=30
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
    if  [[  "$ENV"X == "-t"X  ]] || [[ "$ENV"X == "-f"X ]]  ||  [[ "$ENV"X == "-p"X ]] ;then
         if [ "$ENV"X == "-t"X ];then
            . $CURRENT_DIR/test_env.config
         else
			if  [ "$ENV"X == "-f"X ];then 
            	. $CURRENT_DIR/formal_env.config
			else
				. $CURRENT_DIR/pre_env.config
			fi
         fi
		 if [ ! -z "$deploy_delayed" ];then
			(($deploy_delayed+1))>/dev/null 2>&1
			if [[ $? -eq 0 ]];then
		 		WAITTIME=$deploy_delayed
			fi
	 	 fi
		 import
    else
        echo "cmd: $0 [ -t | -f | -p ]   "
        echo "please input right command"
        echo "example:"
        	echo "$0 -t  //publish test  "
        	echo "$0 -f  //publish formal " 
        	echo "$0 -p  //publish pre " 
         exit
   fi
}
function main_publish(){
	for ipport in $deploy_addrs
	do
		ip=`echo $ipport |awk -F ':' '{print $1}'`
		echo " publish ..........${ipport} "
		url="`echo $sync_config_addr |sed s@ipport_value@$ipport@g`"
		CLASSPATH=$CURRENT_DIR/$SERVICE_NAME-$VERSION/appContent/classes
		url_="`$(eval  echo $url)`"
		if [ "$url_"a == ""a ];then
			echo "WARN : don't find config file by '$url' " >&2;
		else
			echo "scp "$url_" "  $CLASSPATH | /bin/sh >&2 
		fi
		#echo "scp `$(eval  echo $url_)`"  $CLASSPATH | /bin/sh
		dos2unix `ls $CLASSPATH/* |grep -v com ` 2>/dev/null
		#---------------------update ip start-------------------------#
		localIp=$ip
		num=`cat $CLASSPATH/*.rpc|grep ^dubbo.protocol|grep 'host=' -c `
		if [ "$num"a != "0"a ];then
			ip_c=`cat   $CLASSPATH/*.rpc|grep ^dubbo.protocol|grep 'host=' |cut -d'=' -f2`
			key_host=`cat   $CLASSPATH/*.rpc|grep ^dubbo.protocol|grep 'host=' |cut -d'=' -f1`
			if [[ "$ip_c"a == ""a ]] || [[ "$ip_c"a == "localhost"a ]] || [[ "$ip_c"a != "$localIp"a ]];then
				 sed -i "s/^$key_host=.*/$key_host=$localIp/g" $CLASSPATH/*.rpc
			fi
		fi
		num=`cat $CLASSPATH/*.rpc|grep ^appconfig.http.ip -c `
		if [ "$num"a != "0"a ];then
		    ip_c=`cat  $CLASSPATH/*.rpc|grep ^appconfig.http.ip |cut -d'=' -f2`
		    if [[ "$ip_c"a == ""a ]] || [[ "$ip_c"a == "localhost"a ]]  || [[ "$ip_c"a != "$localIp"a ]];then
		         sed -i "s/^appconfig.http.ip=.*/appconfig.http.ip=$localIp/g" $CLASSPATH/*.rpc
		    fi
		fi
		#---------------------update ip stop-------------------------#
		ssh ${deploy_username}@$ip "if [ ! -d $deploy_path ];then mkdir -p $deploy_path ;fi "
		DATE_="`date +%Y%m%d`"
		ssh ${deploy_username}@$ip "ls $deploy_path "|while read v ;do if [[ "$v" =~ "$SERVICE_NAME-" ]];then ssh ${deploy_username}@$ip "sh $deploy_path/$v/bin/stop.sh";fi;done 
		flag="default"
		while(($WAITTIME>0))
		do
			sleep 1
			info=`ssh ${deploy_username}@$ip "ls $deploy_path"` 
			for v in $info; do flag="default" ; if [[ "$v" =~ "$SERVICE_NAME-" ]];then result=`ssh ${deploy_username}@$ip "sh $deploy_path/$v/bin/status.sh"` ;if [[ "$result" =~ "isn't" ]];then continue; else flag=$result;break ;fi ;fi ;done  
			if [[ "$flag" == "default" ]];then
				break;
			fi	
		
			if [[ $WAITTIME -lt 1 ]];then
				echo "Please republish,because the old $flag " >&2;
				break;
			fi
		done
		if [[  "$flag" == "default" ]];then
			DATE_="`date +%Y%m%d`"
	        ssh ${deploy_username}@$ip "if [ -d $deploy_path/$SERVICE_NAME-$VERSION ];then sh $deploy_path/$SERVICE_NAME-$VERSION/bin/stop.sh  ; cp -rf  $deploy_path/$SERVICE_NAME-$VERSION $deploy_path/$SERVICE_NAME-$VERSION.bak.$DATE_ ; rm -rf $deploy_path/$SERVICE_NAME-$VERSION; fi"
			scp  -rd  $CURRENT_DIR/$SERVICE_NAME-$VERSION  ${deploy_username}@$ip:$deploy_path
		else
			(("error"++)) >/dev/null 2>&1
		fi
	done
}
function ln_logdir(){
	if [ -z $logs_path ];then
		logs_path=$deploy_path
	else
		if [[ ! $logs_path =~ ^/ ]];then
			logs_path=$deploy_path/logs_path
		fi

	fi
	if [ ! -z $logs_path ];then
		s_l=$deploy_path/$SERVICE_NAME-$VERSION/log
		ssh ${deploy_username}@$ip "if [[ ! -d  $logs_path/log/${SERVICE_NAME} ]];then mkdir -p $logs_path/log/${SERVICE_NAME};fi;  if [[ -f ${s_l} ]] || [[ -d ${s_l} ]];then mv ${s_l}  ${s_l}.bak ;fi;ln -s -n $logs_path/log/${SERVICE_NAME} ${s_l}"
		m_d=$deploy_path/$SERVICE_NAME-$VERSION/main_data
		ssh ${deploy_username}@$ip "if [[ ! -d  $logs_path/main_data/${SERVICE_NAME} ]];then mkdir -p $logs_path/main_data/${SERVICE_NAME};fi;if [[ -f ${m_d} ]] || [[ -d ${m_d} ]];then mv ${m_d}  ${m_d}.bak;fi;ln -s -n $logs_path/main_data/${SERVICE_NAME} ${m_d}"
	fi
}
function main(){
	check_space
	check_param
	main_publish	>/dev/null
	ln_logdir  >/dev/null
}
echo "start publish ......................"
#running
main
