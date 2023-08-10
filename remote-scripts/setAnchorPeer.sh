#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# 本脚本直接复制于fabric-samples, 其中除了CHANNEL_NAME,其他变量的值都在cli容器中设置过了
# import utils
. remote-scripts/configUpdate.sh
. scripts/utils.sh


# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig ${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"
  PORT=7051
  HOST=$CORE_PEER_ADDRESS

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o ${ORDERER_ADDRESS}:7050 --ordererTLSHostnameOverride ${ORDERER_ADDRESS} -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}


CHANNEL_NAME=$1


createAnchorPeerUpdate 

updateAnchorPeer 
