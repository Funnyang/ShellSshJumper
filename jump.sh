#!/bin/bash

direc=$(dirname $0)

#引入
source edithost.sh
source tools.sh

#jumpTo $id $host $port $user $passwd $logintimes
function jumpTo() {
  local hostItem="$1"
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

  newlogintimes=$logintimes+1

  #更新登录次数
  updateSql='UPDATE "host" SET "LOGIN_TIMES" = '$newlogintimes' WHERE "ID" = '$id

  updateResult=$(sqlite3 $dbName "$updateSql")

  # 当做密码为空时，认为已经配置了免密
  if [[ -z $passwd ]]; then
    echo "ssh $user@$host -p $port"
    ssh $user@$host -p $port
  else
    # echo "expect -f $direc/ssh_login.exp $host $user $passwd $port"
    expect -f $direc/ssh_login.exp $host $user $passwd $port
  fi

}

function usage(){
  echo 
  echo "             1) 输入 $(color green ID) 直接登录."
  echo "             2) 输入 $(color green '部分IP、主机名、备注') 进行搜索登录(如果唯一)."
  echo "             3) 输入 $(color green '/ + IP，主机名 or 备注') 进行搜索，如：/192.168."
  echo "             4) 输入 $(color green p) 显示主机列表"
  echo "             5) 输入 $(color green m) 进行主机管理"
  echo "             6) 输入 $(color green h) 显示帮助"
  echo "             6) 输入 $(color green q) 退出登录"
  echo "             7) 输入 $(color green c) 清屏"
  echo ''
}

function main() {

  checkDb
  usage

  # shellcheck disable=SC2078
  while :; do
    read -p "Opt> " action
    # 接收到 ctrl + D 时退出，ctrl + D 相当于给输入发送 EOF，读取会失败
    if [[ $? = 1 ]]; then
      exit 0
    fi
    case "$action" in
    p)
      listHost
      ;;
    m)
      manageHost
      ;;
    h)
      usage
      ;;
    q)
      exit 0
      ;;
    c)
      clear
      ;;
    *)
      if [[ -n $action ]]; then
        jumpHost $action
      fi
      ;;
    esac
    continue
  done
}

function manageHost() {
  while :; do
    color blue '             a => 添加host'
    color blue '             d => 删除host'
    color blue '             u => 更新host'
    color blue '             q => 返回上级'
    read -p "Opt> " action
    case "$action" in
      a)
        addHost
        line
        ;;
      d)
        delHost
        line
        ;;
      u)
        updateHost
        line
        ;;
      q)
        main
        ;;
      *)
        line
        ;;
    esac
    continue
  done
}

function _query_host(){
  local where=$1
  # 查询主机
  whereSql=''
  [[ -n $where ]] && whereSql="where $where "
  orderSql=' order by "LOGIN_TIMES" DESC'
  selectSql='select "ID","HOST","PORT","USER","PASSWD","LOGIN_TIMES","DESC" from "host"'$whereSql$orderSql';'
  # 查询结果
  sqlite3 $dbName "$selectSql"
}

function _query_host_by_id(){
  local id=$1
  where=' ID='$keyword
  _query_host $where
}

function _query_host_by_keyword(){
  local keyword=$1
  #是字符，模糊搜索其他字段"HOST", "USER", "PASSWD", "DESC"
  where=' HOST LIKE "%'$keyword'%" OR USER LIKE "%'$keyword'%" OR PASSWD LIKE "%'$keyword'%" OR DESC LIKE "%'$keyword'%"'
  _query_host $where
}

function jumpHost() {
  local keyword=$1
  case $keyword in
  [0-9] | [0-9][0-9] | [0-9][0-9][0-9])
    #是数字，按照ID搜索
    where=' ID='$keyword
    selectResult=$(_query_host_by_id $keyword)
    if [[ -z $selectResult ]]; then
      selectResult=$(_query_host_by_keyword $keyword)
    fi
    ;;
  *)
    #是字符，模糊搜索其他字段"HOST", "USER", "PASSWD", "DESC"
    selectResult=$(_query_host_by_keyword $keyword)
    ;;
  esac
  # selectResult
  #格式id|host|port|user|passwd|logintimes|desc id|host|port|user|passwd|logintimes|desc
  # 结果数组
  selectResultArr=(${selectResult//\ / })
  # 结果条数
  selectResultArrSize=${#selectResultArr[*]}
  printHostList $selectResult
  # 当只有一条结果时，直接登录
  if [[ $selectResultArrSize == 1 ]]; then 
    hostItem=${selectResultArr[0]}
    #格式id|host|port|user|passwd|logintimes|desc
    jumpTo "$hostItem"

  else
    read -p '[*] 选择主机: ' keyword
    jumpHost $keyword
  fi
}

logo
main
