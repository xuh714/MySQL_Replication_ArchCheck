#!/bin/bash
# 2020-05-20 MySQL master slave replication architecture detection Script version 1.0 (Author : xuh)
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
alias mastertagCMD=$(echo 'mysql $connCMD -e"select Command from information_schema.processlist where Command in ('"'"Binlog Dump"'"','"'"Binlog Dump GTID"'"','"'"Connect"'"') order by Command ASC;" 2>/dev/null|awk '"'"NR\>1"'"'|uniq|awk '"'"'{for(i=1;i<=NF;i++)printf $i " ";printf "\n"}'"'"'|sed -e '"'"'s/[ ]*$//g'"'"'|awk '"'"'BEGIN{ORS=","}{print $0}'"'")
alias masteruuidsCMD=$(echo 'mysql $connCMD -e"show slave hosts;" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $NF}'"'"' > $log')
alias masteruuidCMD=$(echo 'mysql $connCMD -e"show global variables where variable_name='"'"server_uuid"'"';" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $NF}'"'")
alias masterseridsCMD=$(echo 'mysql $connCMD -e"show slave hosts;" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $1}'"'"' > $log')
alias masterseridCMD=$(echo 'mysql $connCMD -e"show global variables where variable_name='"'"server_id"'"';" 2>/dev/null|awk '"'"NR\>1"'"'|awk '"'"'{print $NF}'"'")
mysqlVer1=`mysql $connCMD1 -e"select substring_index(substring_index(version(),'-',1),'.',2);" 2>/dev/null|awk '{print $1}'|awk 'NR>1'`
mysqlVer2=`mysql $connCMD2 -e"select substring_index(substring_index(version(),'-',1),'.',2);" 2>/dev/null|awk '{print $1}'|awk 'NR>1'`
if [ `echo "$mysqlVer1 == 5.5"|bc` -eq 1 ] || [ `echo "$mysqlVer2 == 5.5"|bc` -eq 1 ];then
#echo "...START1..."
connCMD=$connCMD1
mastertag=`mastertagCMD`
OLD_IFS="$IFS"
IFS=","
array=($mastertag)
IFS="$OLD_IFS"
if [ -n "$mastertag" ] && [ "${array[0]}" == "Binlog Dump" ] || [ "${array[0]}" == "Binlog Dump GTID" ] && [ "${array[1]}" == "Connect" ];then
masterseridsCMD
arrmaster1=($(awk '{print $NF}' $log))
master1serid=`masterseridCMD`
connCMD=$connCMD2
mastertag=`mastertagCMD`
OLD_IFS="$IFS"
IFS=","
array=($mastertag)
IFS="$OLD_IFS"
if [ -n "$mastertag" ] && [ "${array[0]}" == "Binlog Dump" ] || [ "${array[0]}" == "Binlog Dump GTID" ] && [ "${array[1]}" == "Connect" ];then
masterseridsCMD
arrmaster2=($(awk '{print $NF}' $log))
master2serid=`masterseridCMD`
i=0
for arr in ${arrmaster1[@]}
do
if [ "$arr" == "$master2serid" ];then
let i++
fi
done
j=0
for arr in ${arrmaster2[@]}
do
if [ "$arr" == "$master1serid" ];then
let j++
fi
done
if [ $i -eq 1 ] && [ $j -eq 1 ];then
stdopt="YES"
else
stdopt="NO"
fi
else
stdopt="NO"
fi
else
stdopt="NO"
fi
else
#echo "...START2..."
connCMD=$connCMD1
mastertag=`mastertagCMD`
OLD_IFS="$IFS"
IFS=","
array=($mastertag)
IFS="$OLD_IFS"
if [ -n "$mastertag" ] && [ "${array[0]}" == "Binlog Dump" ] || [ "${array[0]}" == "Binlog Dump GTID" ] && [ "${array[1]}" == "Connect" ];then
masteruuidsCMD
arrmaster1=($(awk '{print $NF}' $log))
master1uuid=`masteruuidCMD`
connCMD=$connCMD2
mastertag=`mastertagCMD`
OLD_IFS="$IFS"
IFS=","
array=($mastertag)
IFS="$OLD_IFS"
if [ -n "$mastertag" ] && [ "${array[0]}" == "Binlog Dump" ] || [ "${array[0]}" == "Binlog Dump GTID" ] && [ "${array[1]}" == "Connect" ];then
masteruuidsCMD
arrmaster2=($(awk '{print $NF}' $log))
master2uuid=`masteruuidCMD`
i=0
for arr in ${arrmaster1[@]}
do
if [ "$arr" == "$master2uuid" ];then
let i++
fi
done
j=0
for arr in ${arrmaster2[@]}
do
if [ "$arr" == "$master1uuid" ];then
let j++
fi
done
if [ $i -eq 1 ] && [ $j -eq 1 ];then
stdopt="YES"
else
stdopt="NO"
fi
else
stdopt="NO"
fi
else
stdopt="NO"
fi
fi
echo $stdopt
test -e $log && rm -f $log
#./mmrepl.sh 192.168.239.53 osmproxy okp@admin123 3305 192.168.239.54 osmproxy okp@admin123 3305
