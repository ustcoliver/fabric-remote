#!/bin/bash

# . scripts/deploy-utils.sh
. scripts/utils.sh
. scripts/env.sh

function prepare() {
  println "executing with the following"
  println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
  println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
  println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
  println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
  println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
  println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
  println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
  println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
  println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
  println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
  println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
  println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"
  infoln "\n Vendoring Go dependencies at ${CC_SRC_PATH} ... \n"
  FABRIC_CFG_PATH=$PWD/config/
  CC_RUNTIME_LANGUAGE=golang
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  successln "Finished vendoring Go dependencies"
}

packageChaincode() {
  CC_VERSION="1.0"
  infoln "\n Package the Chaincode ...\n"
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang golang --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
  # 必须要将权限从600修改为至少644,否则无法复制到另一个vm
  chmod 666 ${CC_NAME}.tar.gz
}

# installChaincode PEER ORG
installChaincode() {
  infoln "\n Install the Chaincode on $ORG... \n"
  set -x
  peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.org${ORG} has failed"
  successln "Chaincode is installed on peer0.org${ORG}"
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  infoln "\n Query the Chaincode installed on $ORG... \n"
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.org${ORG} has failed"
  successln "Query installed successful on peer0.org${ORG} on channel"
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  infoln "\n Approve the Chaincode installed for $ORG... \n"
  set -x
  peer lifecycle chaincode approveformyorg -o ${ORDERER_ADDRESS}:7050 --ordererTLSHostnameOverride ${ORDERER_ADDRESS} --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME'"
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  infoln "\n Check the Approval of Chaincode on $ORG... \n"
  shift 1
  infoln "Checking the commit readiness of the chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to check the commit readiness of the chaincode definition on peer0.${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=0
    for var in "$@"; do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    infoln "Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID!"
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  CC_VERSION="1.0"
  infoln "\n Commit the Chaincode \n"
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  set -x
  peer lifecycle chaincode commit -o ${ORDERER_ADDRESS}:7050 --ordererTLSHostnameOverride ${ORDERER_ADDRESS} --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# queryCommitted ORG
queryCommitted() {
  infoln "\n Query the Commitation on $ORG... \n"
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  infoln "Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID!"
  fi
}

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  infoln "\n Init the  Chaincode \n"
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
  infoln "invoke fcn call:${fcn_call}"
  set -x
  peer chaincode invoke -o ${ORDERER_ADDRESS}:7050 --ordererTLSHostnameOverride ${ORDERER_ADDRESS} --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS -c ${fcn_call} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

chaincodeQuery() {
  CC_QUERY=$1
  # setGlobals $ORG
  infoln "\n Querying on peer0.${ORG} on channel '$CHANNEL_NAME'... \n"
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query peer0.${ORG}, Retry after $DELAY seconds."
    fcn_query='{"function":"'${CC_QUERY}'","Args":[]}'
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c $fcn_query >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query successful on peer0.${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID!"
  fi
}

#peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"TransferAsset","Args":["asset6","Christopher"]}'

chaincodeInvoke() {
  parsePeerConnectionParameters $@
  res=$?
  infoln "\n Invoke the  Chaincode \n"
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  fcn_call='{"function":"'${CC_INVOKE}'","Args":[]}'
  infoln "invoke fcn call:${fcn_call}"
  set -x
  peer chaincode invoke -o ${ORDERER_ADDRESS}:7050 --ordererTLSHostnameOverride ${ORDERER_ADDRESS} --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS -c ${fcn_call} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

function install() {
  # 安装链码
  installChaincode

  # 查询安装
  queryInstalled

  # 同意安装
  approveForMyOrg

  checkCommitReadiness
}

command=$1
shift

if [ "${command}" == "" ]; then
  echo "help"
elif [ "$command" == "package" ]; then
  CC_NAME=$1
  CC_SRC_PATH=$2
  packageChaincode
elif [ "$command" == "install" ]; then
  CC_NAME=$1
  CHANNEL_NAME=$2
  ORG=$3
  installChaincode
  queryInstalled
  approveForMyOrg
  checkCommitReadiness
elif [ "$command" == "commit" ]; then
  CC_NAME=$1
  CHANNEL_NAME=$2
  shift 2
  ORG=$*
  commitChaincodeDefinition $ORG
elif [ "$command" == "query-commit" ]; then
  CC_NAME=$1
  CHANNEL_NAME=$2
  ORG=$3
  queryCommitted
elif [ "$command" == "init" ]; then
  CC_NAME=$1
  CHANNEL_NAME=$2
  shift 2
  ORG=$*
  chaincodeInvokeInit $ORG
elif [ "$command" == "query" ]; then
  CC_NAME=$1
  CHANNEL_NAME=$2
  ORG=$3
  chaincodeQuery $4
elif [ "$command" == "invoke" ]; then
  CC_NAME=$1
  CHANNEL_NAME=$2
  ORG=$3
  INVOKE_ARG=$@
  chaincodeInvoke $ORG
else
  errorln "wrong input !!"
fi
