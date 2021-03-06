#!/bin/bash

source tools.sh

direc=$(dirname $0)
dbName='sshJump.db'
initSqlFile='init.sql'
execSqlFile='exec.sql'

#检查DB如有问题修复
function checkDb() {

  #检查初始化文件
  [[ ! -e $initSqlFile ]] && color red 'loss '$initSqlFile' ! please check project' && exit
  #检查初始化数据
  sqlite3 $dbName <$initSqlFile

  #库不存在初始化库
  #[[ ! -e $dbName ]] && sqlite3 $dbName < $initSqlFile
  #tableExist=$(sqlite3 $dbName 'select count(*)  from sqlite_master where type="table" and name = "host";')
  #表不存在,初始化
  #[[ $tableExist == 0 ]] && sqlite3 $dbName < $initSqlFile

}

function addHost() {

  read -p '请输入主机Host: ' host
  [[ -z $host ]] && echo '主机Host不能为空'

  read -p '请输入主机端口(22): ' port
  [[ -z $port ]] && port=22

  read -p '请输入登录用户名(root): ' user
  [[ -z $user ]] && user='root'

  read -s -p '请输入登录密码(不填则使用免密登录): ' passwd
  [[ -z $passwd ]] && echo '将使用默认私钥登录'
  echo

  read -p '请输入主机描述: ' desc
  [[ -z $host ]] && desc=$host

  create_time=update_time=$(date '+%Y-%m-%d %H:%M:%S')

  color blue '新增登录主机 '$user':'$passwd'@'$host':'$port' '$desc
  read -p '是否新增登录主机?  [y/n]' confirm
  [[ $confirm != 'y' ]] && return

  insertSql='INSERT INTO "host" ( "HOST", "PORT", "USER", "PASSWD", "DESC", "CREATE_TIME", "UPDATE_TIME") VALUES ("'$host'",'$port',"'$user'","'$passwd'","'$desc'","'$create_time'","'$update_time'");'

  #echo 'insertSql:'$insertSql

  echo $(sqlite3 $dbName "$insertSql")
  #echo $(sqlite3 $dbName  'select * from host')

}

function delHost() {

  read -p '请输入主机ID: ' id
  [[ -z $id ]] && echo '要删除主机id不能为空' && return
  echo $id | grep -q '[^0-9]' >/dev/null && echo 'ID 必须是数字' && return

  delSql='DELETE FROM "host" WHERE "ID"='$id';'

  #echo 'delSql'$delSql

  # shellcheck disable=SC2046
  echo $(sqlite3 $dbName "$delSql")

  return
}

#$1 where
#格式id|host|port|user|passwd|logintimes|desc id|host|port|user|passwd|logintimes|desc
# shellcheck disable=SC2120
function listHost() {
  local where="$1"
  
  whereSql=''
  [[ -n $where ]] && whereSql="where $where "
  orderSql=' order by "LOGIN_TIMES" DESC'
  selectSql='select "ID","HOST","PORT","USER","PASSWD","LOGIN_TIMES","DESC" from "host"'$whereSql$orderSql';'

  #  echo $selectSql

  selectResult=$(sqlite3 $dbName "$selectSql")
  printHostList "$selectResult"
}

function printHostList() {
  local selectResult=$1
  #格式id|host|port|user|passwd|logintimes|desc id|host|port|user|passwd|logintimes|desc
  echo "序号 |       主机       | 连接次数 | 说明"
  
  selectResultArr=(${selectResult//\ / })
  selectResultArrSize=${#selectResultArr[*]}

  # shellcheck disable=SC2068
  for hostItem in ${selectResultArr[@]}; do
    #格式id|host|port|user|passwd|logintimes|desc
    id=host=port=user=passwd=logintimes=desc=''

    #字段赋值
    oldIFS=$IFS
    IFS="|"
    count=0
    for item in $hostItem
    do
      [ $count -eq 0 ] && id=$item
      [ $count -eq 1 ] && host=$item
      [ $count -eq 2 ] && port=$item
      [ $count -eq 3 ] && user=$item
      [ $count -eq 4 ] && passwd=$item
      [ $count -eq 5 ] && logintimes=$item
      [ $count -eq 6 ] && desc=$item
      let count++
    done
    IFS=$oldIFS

    printf "\033[0;33m% 3s \033[m | %16s | %9s| %s\n" $id $host $logintimes $desc

  done
  echo
}

function updateHost() {

  read -p '请输入主机ID: ' id
  [[ -z $id ]] && echo '主机id不能为空' && return
  echo $id | grep -q '[^0-9]' >/dev/null && echo 'ID 必须是数字' && return

  hostExist=$(sqlite3 $dbName 'select count(*)  from "host" WHERE "ID" = '$id';')
  [[ $hostExist == 0 ]] && echo "主机ID不存在" && return

  update_time=$(date '+%Y-%m-%d %H:%M:%S')
  setField='SET "UPDATE_TIME" = "'$update_time'"'

  read -p '请输入主机Host: ' host
  #不为空更新
  if [[ -n "$host" ]]; then
    setField=$setField' ,"HOST" = "'$host'"'
  fi

  read -p '请输入主机端口: ' port
  if [[ -n "$port" ]]; then
    setField=$setField' ,"PORT" = '$port
  fi

  read -p '请输入登录用户名: ' user
  if [[ -n "$user" ]]; then
    setField=$setField' ,"USER" = "'$user'"'
  fi

  read -p '请输入登录密码: ' passwd
  if [[ -n "$passwd" ]]; then
    setField=$setField' ,"PASSWD" = "'$passwd'"'
  fi

  read -p '请输入主机描述: ' desc
  if [[ -n "$desc" ]]; then
    setField=$setField' ,"DESC" = "'$desc'"'
  fi

  updateSql='UPDATE "host" '$setField' WHERE "ID" = '$id' ;'

  #echo 'updateSql'$updateSql

  updateResult=$(sqlite3 $dbName "$updateSql")
  echo 'updateResult'$updateResult
}
