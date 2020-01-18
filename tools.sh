#!/bin/bash

function color(){
    blue="\033[0;36m"
    red="\033[0;31m"
    green="\033[0;32m"
    yellow="\033[0;33m"
    white="\033[0;37m"
    close="\033[m"
    case $1 in
        blue)
            echo -e "$blue$2$close"
        ;;
        red)
            echo -e "$red$2$close"
        ;;
        green)
            echo -e "$green$2$close"
        ;;
        yellow)
            echo -e "$yellow$2$close"
        ;;
        white)
            echo -e "$white$2$close"
        ;;
        *)
            echo "Input color error!!"
        ;;
    esac
}


function line() {
  echo "-----------------------------------------"
}


function logo() {
  echo 
  color green "             欢迎使用堡垒机系统!"
#   color green "git https://github.com/timsengit/ShellSshJumper "
}

function _exit(){
    echo "信号"
    exit 0
}
