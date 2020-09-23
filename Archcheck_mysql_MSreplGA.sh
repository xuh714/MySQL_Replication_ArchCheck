#!/bin/bash
unset MAILCHECK
ker=`uname`
if [[ $ker = "Linux" ]]; then
    . ~/.bash_profile >/dev/null 2>&1
    export LANG=en_US.UTF-8
else
    . ~/.profile >/dev/null 2>&1 
    test $ker = "AIX" && export LANG=en_US || export LANG=en_US.utf8
fi
DEBUG_FLG='McDeBuG'
test $# = 0 && my_debug_flg=McDeBuGd || my_debug_flg=`echo $*| awk '{print $NF}'`
if [[ "$my_debug_flg" = "$DEBUG_FLG" ]]; then
    export PS4='+{$LINENO:${FUNCNAME[0]}} '
    set -x
    echo args=$@
fi
cd /tmp
log=mc${$}.txt
connCMD1="-h$1 -u$2 -p$3 -P$4"
connCMD2="-h$5 -u$6 -p$7 -P$8"
CMDopt=`mysql $connCMD1 -e"select 1;" 2>/dev/null |awk 'NR>1'`
if [ ! -n "$CMDopt" ] || [ $CMDopt -ne 1 ];then
echo "Abnormal"
exit 0
fi
CMDopt=`mysql $connCMD2 -e"select 1;" 2>/dev/null |awk 'NR>1'`
if [ ! -n "$CMDopt" ] || [ $CMDopt -ne 1 ];then
echo "Abnormal"
exit 0
fi
shopt -s expand_aliases
alias mastertagCMD=$(echo 'mysql $connCMD -e"select Command from information_schema.processlist where Command in ('"'"Binlog Dump"'"','"'"Binlog Dump GTID"'"');" 2>/dev/null|awk '"'"NR\>1"'"'|uniq|awk '"'"'{for(i=1;i<=NF;i++)printf $i " ";printf "\n"}'"'"'|sed -e '"'"'s/[ ]*$//g'"'")
alias slavetagCMD=$(echo 'mysql $connCMD -e"select Command from information_schema.processlist where Command='"'"Connect"'"';" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $NF}'"'"'|uniq')
alias slaveuuidsCMD=$(echo 'mysql $connCMD -e"show slave hosts;" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $NF}'"'"' > $log')
alias slaveuuidCMD=$(echo 'mysql $connCMD -e"show global variables where variable_name='"'"server_uuid"'"';" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $NF}'"'")
alias slaveseridsCMD=$(echo 'mysql $connCMD -e"show slave hosts;" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $1}'"'"' > $log')
alias slaveseridCMD=$(echo 'mysql $connCMD -e"show global variables where variable_name='"'"server_id"'"';" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $NF}'"'")
mysqlVer1=`mysql $connCMD1 -e"select substring_index(substring_index(version(),'-',1),'.',2);" 2>/dev/null|awk '{print $1}'|awk 'NR>1'`
mysqlVer2=`mysql $connCMD2 -e"select substring_index(substring_index(version(),'-',1),'.',2);" 2>/dev/null|awk '{print $1}'|awk 'NR>1'`
if [ `echo "$mysqlVer1 == 5.5"|bc` -eq 1 ] || [ `echo "$mysqlVer2 == 5.5"|bc` -eq 1 ];then
#echo "...START1..."
connCMD=$connCMD1
mastertag=`mastertagCMD`
if [ "$mastertag" == "Binlog Dump" ] || [ "$mastertag" == "Binlog Dump GTID" ];then
slaveseridsCMD
connCMD=$connCMD2
slavetag=`slavetagCMD`
if [ "$slavetag" == "Connect" ];then
slaveserid=`slaveseridCMD`
while read line
do
if [ "$line" == "$slaveserid" ];then
stdopt="YES"
break
fi
done < $log
if [ ! -n "$stdopt" ];then
stdopt="NO"
fi
else
stdopt="NO"
fi
elif [ ! -n "$mastertag" ];then
slavetag=`slavetagCMD`
if [ "$slavetag" == "Connect" ];then
slaveserid=`slaveseridCMD`
connCMD=$connCMD2
mastertag=`mastertagCMD`
if [ "$mastertag" == "Binlog Dump" ] || [ "$mastertag" == "Binlog Dump GTID" ];then
slaveseridsCMD
while read line
do
if [ "$line" == "$slaveserid" ];then
stdopt="YES"
break
fi
done < $log
if [ ! -n "$stdopt" ];then
stdopt="NO"
fi
else
stdopt="NO"
fi
else
stdopt="NO"
fi
else
stdopt="Abnormal"
fi
else
#echo "...START2..."
connCMD=$connCMD1
mastertag=`mastertagCMD`
if [ "$mastertag" == "Binlog Dump" ] || [ "$mastertag" == "Binlog Dump GTID" ];then
slaveuuidsCMD
connCMD=$connCMD2
slavetag=`slavetagCMD`
if [ "$slavetag" == "Connect" ];then
slaveuuid=`slaveuuidCMD`
while read line
do
if [ "$line" == "$slaveuuid" ];then
stdopt="YES"
break
fi
done < $log
if [ ! -n "$stdopt" ];then
stdopt="NO"
fi
else
stdopt="NO"
fi
elif [ ! -n "$mastertag" ];then
slavetag=`slavetagCMD`
if [ "$slavetag" == "Connect" ];then
slaveuuid=`slaveuuidCMD`
connCMD=$connCMD2
mastertag=`mastertagCMD`
if [ "$mastertag" == "Binlog Dump" ] || [ "$mastertag" == "Binlog Dump GTID" ];then
slaveuuidsCMD
while read line
do
if [ "$line" == "$slaveuuid" ];then
stdopt="YES"
break
fi
done < $log
if [ ! -n "$stdopt" ];then
stdopt="NO"
fi
else
stdopt="NO"
fi
else
stdopt="NO"
fi
else
stdopt="Abnormal"
fi
fi
echo $stdopt
test -e $log && rm -f $log
#./msrepl.sh 192.168.239.51 osmproxy okp@admin123 3305 192.168.239.52 osmproxy okp@admin123 3305