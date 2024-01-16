#!/bin/bash

. scripts/utils.sh
. scripts/env.sh
. remote-scripts/env.sh
. remote-scripts/ccp-generate.sh

function ca_up() {
  container_exist=$(docker-compose ps -q ${CA_CONTAINER})
  if [ $container_exist ]; then
    infoln "container already exist on ${HOST_IP}, skip ..."
  else
    infoln "start fabric-ca container on ${HOST_IP}..."
    docker-compose up -d ${CA_CONTAINER}
  fi
}

function generate_org() {
  export PATH=$PATH:${HOME}/fabric-samples/bin
  infoln "Enrolling the CA admin for ${ORG_ADDR}"
  mkdir -p organizations/peerOrganizations/${ORG_ADDR}
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${ORG_ADDR}
  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ${CA_NAME} --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Adding org msp config.yaml"
  echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
      Certificate: cacerts/localhost-7054-${CA_NAME}.pem
      OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
      Certificate: cacerts/localhost-7054-${CA_NAME}.pem
      OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
      Certificate: cacerts/localhost-7054-${CA_NAME}.pem
      OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
      Ceairtificate: cacerts/localhost-7054-${CA_NAME}.pem
      OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/peerOrganizations/${ORG_ADDR}/msp/config.yaml

  infoln "Registering peer0 "
  set -x
  fabric-ca-client register --caname ${CA_NAME} --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ${CA_NAME} --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ${CA_NAME} --id.name ${ORG_NAME}admin --id.secret ${ORG_NAME}adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ${CA_NAME} -M ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/msp --csr.hosts ${PEER0_ADDR} --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Copying org msp config to peer0 msp config"
  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/msp/config.yaml ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/msp/config.yaml

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ${CA_NAME} -M ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls --enrollment.profile tls --csr.hosts ${PEER0_ADDR} --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Copying to ca.crt, server.crt, server.key"
  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/signcerts/* ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/keystore/* ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/server.key

  infoln "Copying peer0 tlsca certificates to org msp tlscacerts"
  mkdir -p ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/msp/tlscacerts/ca.crt

  infoln "Copying peer0 tls certificates to org tlsca"
  mkdir -p ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/tlsca
  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/tlsca/tlsca.${ORG_ADDR}-cert.pem

  infoln "Copying peer0 msp cacerts to org ca "
  mkdir -p ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/ca
  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/peers/${PEER0_ADDR}/msp/cacerts/* ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/ca/${CA_ADDR}-cert.pem

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ${CA_NAME} -M ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/users/User1@${ORG_ADDR}/msp --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/msp/config.yaml ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/users/User1@${ORG_ADDR}/msp/config.yaml

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://${ORG_NAME}admin:${ORG_NAME}adminpw@localhost:7054 --caname ${CA_NAME} -M ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/users/Admin@${ORG_ADDR}/msp --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/msp/config.yaml ${PWD}/organizations/peerOrganizations/${ORG_ADDR}/users/Admin@${ORG_ADDR}/msp/config.yaml
}
function generate_orderer() {
  export PATH=$PATH:${HOME}/fabric-samples/bin
  infoln "Enrolling the CA admin for ${ORDERER_ADDR}"
  mkdir -p organizations/ordererOrganizations/${ORG_DOMAIN}
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}
  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ${CA_NAME} --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-${CA_NAME}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-${CA_NAME}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-${CA_NAME}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-${CA_NAME}.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/msp/config.yaml

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ${CA_NAME} --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ${CA_NAME} --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:7054 --caname ${CA_NAME} -M ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/msp --csr.hosts ${ORDERER_ADDR} --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Copying orderer msp config"
  cp ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/msp/config.yaml ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/msp/config.yaml

  infoln "Generating the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:7054 --caname ${CA_NAME} -M ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls --enrollment.profile tls --csr.hosts ${ORDERER_ADDR} --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Copying to ca.crt, server.crt, server.key"
  cp ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/keystore/* ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/server.key

  infoln "Copying orderer tlsca certificates to orderer msp tlscacerts"
  mkdir -p ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/msp/tlscacerts/tlsca.${ORG_DOMAIN}-cert.pem

  infoln "Copying orderer msp tlsca certificates to orderer msp tlscacerts"
  mkdir -p ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/orderers/${ORDERER_ADDR}/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/msp/tlscacerts/tlsca.${ORG_DOMAIN}-cert.pem

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:7054 --caname ${CA_NAME} -M ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/users/Admin@${ORG_DOMAIN}/msp --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/msp/config.yaml ${PWD}/organizations/ordererOrganizations/${ORG_DOMAIN}/users/Admin@${ORG_DOMAIN}/msp/config.yaml
}

command=$1
shift 1

if [ "$command" == "up" ]; then
  ca_up
elif [ "$command" == "generate" ]; then
  while :; do
    if [ ! -f "${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem" ]; then
      files=$(ls ${PWD}/organizations/fabric-ca/${ORG_NAME})
      echo "now files: ${files}"
      echo "wait for fabric-ca to generate tls-cert.pem, sleep 1s ..."
      sleep 1
    else
      break
    fi
  done
  generate_org
  generate_orderer
  generate_ccp
else
  echo "wrong input !!"
fi
