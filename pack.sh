#!/bin/bash
CURRENT_DIR=`pwd`
SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR=`cd $SCRIPT_DIR;pwd`
SERVICE_NAME=DEFAULT
PROJECT_NAME=DEFAULT
VERSION=DEFAULT
SUBSRCDIR="src/main/java"
RESOURCEDIR="src/main/resources"
function checkSrc(){
	if [ ! -d "$CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR" ];then
		SUBSRCDIR="src"
	fi
	if [ ! -d "$CURRENT_DIR/$PROJECT_NAME/$RESOURCEDIR" ];then
		RESOURCEDIR="src"
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
function copy_dependency(){
	if [ -f $CURRENT_DIR/$PROJECT_NAME/pom.xml ];then
		cd $CURRENT_DIR/$PROJECT_NAME;mvn dependency:copy-dependencies
		cd $CURRENT_DIR
	fi
}
function import(){
	if [[ -f  $CURRENT_DIR/.tmp_param.bak ]];then
		. $CURRENT_DIR/.tmp_param.bak
	else
		"The first,to execute checkout.sh,please!"
		exit 1
	fi
}
function pack_server(){
	lib=$CURRENT_DIR/$SERVICE_NAME-$VERSION/appContent/lib
	if [ ! -d "$lib" ];then
		mkdir -p  $lib
	fi
	srclib="$CURRENT_DIR/$PROJECT_NAME/lib"
	if [ -d $srclib ];then
		 yes|cp ${srclib}/*.jar $lib 2>/dev/null
	fi
	srcmlib="$CURRENT_DIR/$PROJECT_NAME/mlib" 
	if [ -d $srcmlib ];then
		 yes|cp ${srcmlib}/*.jar $lib 2>/dev/null
	fi
	find $CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR -name '*.java' > $CURRENT_DIR/.sources.list
	sources="$CURRENT_DIR/.sources.list"
	classPath=$CURRENT_DIR/$SERVICE_NAME-$VERSION/appContent/classes
	if [ ! -d "$classPath" ];then
		mkdir -p  $classPath
	fi
	jars=`echo $CURRENT_DIR/$SERVICE_NAME-$VERSION/appContent/lib/*.jar|tr ' ' ':'`
	javac -classpath $jars  -d $classPath @$sources
	rm_temp_dir=`ls -R $classPath/ |grep -e "$SERVICE_NAME":$`
	rm_temp_dir=`dirname "$rm_temp_dir"`
	tem_=`grep $SERVICE_NAME $rm_temp_dir`	
	if [ ! -z "$tem_" ];then
		ls $rm_temp_dir|grep -v $SERVICE_NAME |while read v
		do
			rm -rf $rm_temp_dir/$v
		done
	fi
   	find $CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR/com -type f|grep -v -E *java$ |while read v
    do
            non_java_dir=`dirname $v`
            non_jar_dir=`echo $non_java_dir|sed s@$CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR@$classPath@g`
            if [ ! -d $non_jar_dir ];then
                    mkdir -p $non_jar_dir
            fi
            cp $v $non_jar_dir
    done
	rm -rf $CURRENT_DIR/.sources.list
	config=`find  $CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR -maxdepth 1 -type f|xargs|sed  "s/ / /g"`;	
	if [ x"$config" != x"" ];then
		yes|cp -rd  $config $classPath
	fi
	if [ -d "$CURRENT_DIR/$PROJECT_NAME/$RESOURCEDIR" ]&&[ "$CURRENT_DIR/$PROJECT_NAME/$RESOURCEDIR" != "$CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR" ];then
    	config=`find  $CURRENT_DIR/$PROJECT_NAME/$RESOURCEDIR -maxdepth 1 -type f|xargs|sed  "s/ / /g"`;
    	if [ x"$config" != x"" ];then
        	yes|cp -rd  $config $classPath
    	fi
	fi
	bin=$CURRENT_DIR/$SERVICE_NAME-$VERSION/bin
	if [ ! -d "$bin" ];then
		mkdir -p $bin
	fi
	cp -rd  $CURRENT_DIR/$PROJECT_NAME/sbin/*  $bin	
	main_data=$CURRENT_DIR/$SERVICE_NAME-$VERSION/main_data
	if [ ! -d "$main_data" ];then
	   mkdir -p $main_data
	   echo "the current dir is the data's dir of app" >$main_data/README.ME
	fi
	doc=$CURRENT_DIR/$SERVICE_NAME-$VERSION/doc
	if [ ! -d "$doc" ];then
		mkdir -p $doc
		ls $CURRENT_DIR/$PROJECT_NAME/doc/|while read value
		do
			v=`echo $value |grep -v -i -E "(\.doc|\.ppt)x?"`			
			if [ $v ];then
				cp -rd  $CURRENT_DIR/$PROJECT_NAME/doc/$v $doc
			fi
		done
	fi
}
function pack_api(){
	 #pack complie
	 find $CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR  -type f -name *.java |grep  -E  "$SERVICE_NAME/iface|$SERVICE_NAME/bean|$SERVICE_NAME/common" >$CURRENT_DIR/.sources.list
	sources="$CURRENT_DIR/.sources.list"
	api=$CURRENT_DIR/$SERVICE_NAME-$VERSION/doc/$SERVICE_NAME-api-$VERSION
    if [ ! -d $api ];then
        mkdir -p  $api
    fi
    jars=`echo $CURRENT_DIR/$SERVICE_NAME-$VERSION/appContent/lib/*.jar|tr ' ' ':'`
    javac -classpath $jars  -d $api @$sources
	#pack source code
	cat $CURRENT_DIR/.sources.list |while read value
	do
		base_source_dir=`echo $value |awk -F "$CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR" '{print $2}'`
		base_source_dir=`dirname $base_source_dir`
		cp $value $api/$base_source_dir
	done
	#pack static resource
	find $CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR/com -type f|grep  -E  "$SERVICE_NAME/iface|$SERVICE_NAME/bean|$SERVICE_NAME/common"|grep -v -E *java$ |grep -v \\.svn/ |while read v
    do
            non_java_dir=`dirname $v`
            non_jar_dir=`echo $non_java_dir|sed s@$CURRENT_DIR/$PROJECT_NAME/$SUBSRCDIR@$classPath@g`
            if [ ! -d $non_jar_dir ];then
                    mkdir -p $non_jar_dir
            fi
            cp $v $non_jar_dir
    done
    rm -rf $CURRENT_DIR/.sources.list
	vs=`echo $VERSION|awk -F'.dy' '{print $1}'`
	cd $api;
    jar -cf $CURRENT_DIR/$SERVICE_NAME-$VERSION/doc/$SERVICE_NAME-api-$vs.jar ./
    cd $CURRENT_DIR
	rm -rf $api
	echo $api >>test.log
}
function main(){
	check_space
	import #>/dev/null
	copy_dependency #>/dev/null
	checkSrc
	pack_server #>/dev/null
	pack_api #>/dev/null
}
#running 
main
