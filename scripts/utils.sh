#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

function printHelp() {

  println "\n \t Hyperledger Fabric v2.2 Multihost Deployment Test Project\n"
  println "\n The following are the script parameters: \n "
  infoln "init"
  println "\t remote init project"
  infoln "up"
  println "\t generate and sync cert files and config to vms, start docker containers"
  infoln "channel"
  println "\t create channel, let peers join the channel"
  infoln "deploy"
  println "\t deploy Chaincode, query chaincode to check the chaincode deployment"
  infoln "generate"
  println "\t generate cert files and blockchain config"
  infoln "clean"
  println "\t remove all locally generated cert files and blockchain configs"
  infoln "createChannel"
  println "\t create Channel"
  infoln "down"
  println "\t remote stop all docker containers and remove all cert files and config"
}

# println echos string
function println() {
  echo -e "$1"
}

# errorln echos i red color
function errorln() {
  println "${C_RED}[remote-shell] ${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}[remote-shell] ${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}[remote-shell] ${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}[remote-shell] ${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

# 使用find判断文件是否存在，可以使用通配符删除文件
function removeFiles() {
  FILE=$@
  for file in $FILE; do
    res=$(find $file 2>/dev/null)
    if [ "$res" != "" ]; then
      infoln "remove $file."
      sudo rm -rf $file
    else
      infoln "$file not exist, skip ..."
    fi
  done
}

# 关闭相关容器，流程：
# 1. 判断由此文件夹下docker-compose文件定义的容器是否存在
# 2. 如果存在则基于docker-compose文件将其删除，如果没有则跳过
function removeContainer() {
  containers=$(docker-compose ps -aq)
  IP=$(hostname -I | awk '{print $1}')
  if [ "$containers" != "" ]; then
    infoln "remove all containers on ${IP} ..."
    set -x
    docker-compose down --volumes
    set +x
  else
    infoln "no containers on ${IP}, skip ..."
  fi

}

export -f errorln
export -f successln
export -f infoln
export -f warnln
