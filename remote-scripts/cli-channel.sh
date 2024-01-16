#!/bin/bash

DELAY=3

. remote-scripts/env.sh
. scripts/utils.sh

function createChannel() {
  infoln "\n generate $CHANNEL.block ... \n"
  infoln "\n sleep $DELAY seconds, wait for RAFT consensus to start... \n"
  sleep $DELAY
  set -x
  peer channel create -o $ORDERER_ADDR:7050 -c $CHANNEL -f ./channel-artifacts/$CHANNEL.tx --outputBlock ./channel-artifacts/$CHANNEL.block --tls --cafile $ORDERER_CA -t 60s
  set +x
}

function joinChannel() {
  CHANNEL=$1
  # 检查$CHANNEL.block 文件是否存在，若不存在则推出
  if [ ! -f "./channel-artifacts/$CHANNEL.block" ]; then
    echo -e "\n ./channel-artifacts/$CHANNEL.block not found !!! \n"
    exit 1
  fi
  peer channel join -b ./channel-artifacts/$CHANNEL.block
}

command=$1
shift
args=$@

if [ "$command" == "create" ]; then
  createChannel $args
elif [ "$command" == "join" ]; then
  joinChannel $args
else
  echo "wrong command !!!"
fi
