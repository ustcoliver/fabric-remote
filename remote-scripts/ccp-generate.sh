#!/bin/bash

. remote-scripts/env.sh
. scripts/utils.sh 

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $1)
    local CP=$(one_line_pem $2)
    sed -e "s/\${PROJECT_NAME}/${PROJECT_NAME}/" \
        -e "s/\${ORG_NAME}/${ORG_NAME}/" \
        -e "s/\${ORG_MSP}/${ORG_MSP}/" \
        -e "s/\${PEER0_ADDR}/${PEER0_ADDR}/" \
        -e "s/\${PEER0_PORT}/${PEER0_PORT}/" \
        -e "s/\${CA_NAME}/${CA_NAME}/" \
        -e "s/\${CA_ADDR}/${CA_ADDR}/" \
        -e "s/\${CA_PORT}/${CA_PORT}/" \
        -e "s#\${PEER_PEM}#$PP#" \
        -e "s#\${CA_PEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $1)
    local CP=$(one_line_pem $2)
    sed -e "s/\${PROJECT_NAME}/${PROJECT_NAME}/" \
        -e "s/\${ORG_NAME}/${ORG_NAME}/" \
        -e "s/\${ORG_MSP}/${ORG_MSP}/" \
        -e "s/\${PEER0_ADDR}/${PEER0_ADDR}/" \
        -e "s/\${PEER0_PORT}/${PEER0_PORT}/" \
        -e "s/\${CA_NAME}/${CA_NAME}/" \
        -e "s/\${CA_ADDR}/${CA_ADDR}/" \
        -e "s/\${CA_PORT}/${CA_PORT}/" \
        -e "s#\${PEER_PEM}#${PP}#" \
        -e "s#\${CA_PEM}#${CP}#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}
function generate_ccp {
    infoln "generate ccp files for ${ORG_NAME} on ${HOST_IP} ..."

	PEER_PEM_PATH=organizations/peerOrganizations/${ORG_ADDR}/tlsca/tlsca.${ORG_ADDR}-cert.pem
	CA_PEM_PATH=organizations/peerOrganizations/${ORG_ADDR}/ca/${CA_ADDR}-cert.pem

	echo "$(json_ccp $PEER_PEM_PATH $CA_PEM_PATH)" >organizations/peerOrganizations/${ORG_ADDR}/connection-${ORG_NAME}.json
	echo "$(yaml_ccp $PEER_PEM_PATH $PEER_PEM_PATH)" >organizations/peerOrganizations/${ORG_ADDR}/connection-${ORG_NAME}.yaml
}
