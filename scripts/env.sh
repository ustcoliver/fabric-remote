#!/bin/bash


. scripts/utils.sh

#项目配置
# 项目名
PROJECT_NAME="BigDataExchange"
# 通道设置
CHANNEL_PROFILE="ChannelOne"
# 通道名
CHANNEL_NAME="channelone"

# 节点数量
# 使用eval进行变量名拼接
# 只需HOSTS的值与相应变量的数量统一，即可通过循环执行操作
HOSTS=6
# 节点ip
HOST1="10.2.2.11"
HOST2="10.2.2.12"
HOST3="10.2.2.13"
HOST4="10.2.2.14"
HOST5="10.2.2.15"
HOST6="10.2.2.16"
# 节点ssh host
SSH_HOST1="f1"
SSH_HOST2="f2"
SSH_HOST3="f3"
SSH_HOST4="f4"
SSH_HOST5="f5"
SSH_HOST6="f6"
# 组织名
ORG1="Org1"
ORG2="Org2"
ORG3="Org3"
ORG4="Org4"
ORG5="Org5"
ORG6="Org6"

# 通道名
# CHANNEL_NAME="template-channel"
#等待raft选出leader
DELAY=3
# 尝试创建通道次数，防止raft还未选出leader就提交
MAX_RETRY=3
# 是否已经分发iphosts 到各个主机
# distributeHost 只需运行一次
IPHOST_DISTRIBUTED=false

# 此处存一些智能合约基础环境变量
# 默认所有智能合约都由go编写
CC_SRC_LANGUAGE=go
CC_RUNTIME_LANGUAGE=golang
CC_VERSION="1.0"
CC_SEQUENCE="1"
CC_INIT_FCN="InitLedger"
CC_END_POLICY="NA"
CC_COLL_CONFIG="NA"
VERBOSE="false"
CC_QUERY="GetAllDataSet"



export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.remote.com/peers/peer0.org1.remote.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.remote.com/peers/peer0.org2.remote.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.remote.com/peers/peer0.org3.remote.com/tls/ca.crt
export PEER0_ORG4_CA=${PWD}/organizations/peerOrganizations/org4.remote.com/peers/peer0.org4.remote.com/tls/ca.crt
export PEER0_ORG5_CA=${PWD}/organizations/peerOrganizations/org5.remote.com/peers/peer0.org5.remote.com/tls/ca.crt
export PEER0_ORG6_CA=${PWD}/organizations/peerOrganizations/org6.remote.com/peers/peer0.org6.remote.com/tls/ca.crt

# 设置环境变量
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=peer0.org1.remote.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=peer0.org2.remote.com:7051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_ADDRESS=peer0.org3.remote.com:7051
  elif [ $USING_ORG -eq 4 ]; then
    export CORE_PEER_ADDRESS=peer0.org4.remote.com:7051
  elif [ $USING_ORG -eq 5 ]; then
    export CORE_PEER_ADDRESS=peer0.org5.remote.com:7051
  elif [ $USING_ORG -eq 6 ]; then
    export CORE_PEER_ADDRESS=peer0.org6.remote.com:7051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container 
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=peer0.org1.remote.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=peer0.org2.remote.com:7051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_ADDRESS=peer0.org3.remote.com:7051
  elif [ $USING_ORG -eq 4 ]; then
    export CORE_PEER_ADDRESS=peer0.org4.remote.com:7051
  elif [ $USING_ORG -eq 5 ]; then
    export CORE_PEER_ADDRESS=peer0.org5.remote.com:7051
  elif [ $USING_ORG -eq 6 ]; then
    export CORE_PEER_ADDRESS=peer0.org6.remote.com:7051
  else
    errorln "ORG Unknown"
  fi
}


parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER0_ORG$1_CA")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift by one to get to the next organization
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
  infoln "PEERS: $PEERS"
  infoln "PEER_CONN_PARMS: $PEER_CONN_PARMS"
}