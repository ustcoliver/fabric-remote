. scripts/utils.sh
. scripts/env.sh
. remote-scripts/env.sh

function remoteDown() {
  # PROJECT_NAME=$1
  # IP=$(hostname -I | awk '{print $1}')

  infoln "\n remove blockchain config and cert files on ${HOST_IP} ... \n"

  removeFiles ${HOME}/${PROJECT_NAME}/channel-artifacts

  removeFiles ${HOME}/${PROJECT_NAME}/system-genesis-block

  removeFiles ${HOME}/${PROJECT_NAME}/organizations

  removeFiles ${HOME}/${PROJECT_NAME}/scripts

  removeFiles ${HOME}/${PROJECT_NAME}/remote-scripts

  removeContainer

  removeFiles ${HOME}/${PROJECT_NAME}/docker-compose.yaml

  removeFiles ${HOME}/${PROJECT_NAME}/*.tar.gz

  removeFiles ${HOME}/${PROJECT_NAME}/chaincode

  removeFiles ${HOME}/${PROJECT_NAME}/configtx

  removeIpHost

  removeFiles ${HOME}/${PROJECT_NAME}/iphosts

  removeFiles ${HOME}/${PROJECT_NAME}/hosts
}

function remoteUp() {
  IP=$(hostname -I | awk '{print $1}')

  echo -e "\n start docker containers by docker-compose on ${HOST_IP} ... \n"

  set -x
  docker-compose -f docker/docker-compose-up.yaml up -d
  set +x
  echo -e "\n sleep 3 seconds for containers ...\n"
  sleep 3

  docker ps --format "{{.ID}}\t{{.Status}}\t{{.Names}}"

}

function remoteInit() {
  exist=$(cat /etc/hosts | grep -of ~/${PROJECT_NAME}/iphosts)
  if [ ${exist} ]; then
    infoln "\n ip-hosts already existed, skip ... \n"
  else
    addIpHost
  fi
  mkdir -p chaincode

}

function addIpHost() {
  IP=$(hostname -I | awk '{print $1}')
  infoln "distribute ip hosts and insert to /etc/hosts on $IP..."
  cat /etc/hosts >~/${PROJECT_NAME}/hosts
  cat ~/${PROJECT_NAME}/iphosts | sudo tee -a /etc/hosts >/dev/null
  infoln "\n after that ... \n"
  cat /etc/hosts
}

function removeIpHost() {
  IP=$(hostname -I | awk '{print $1}')
  infoln "restore /etc/hosts to default on $IP"
  sudo cp ~/${PROJECT_NAME}/hosts /etc/hosts
  infoln "\n after that ... \n"
  cat /etc/hosts
}

command=$1
shift 1

if [ "$command" == "init" ]; then
  remoteInit
elif [ "$command" == "up" ]; then
  remoteUp
elif [ "$command" == "down" ]; then
  remoteDown $1
else
  echo "wrong input !!"
fi
