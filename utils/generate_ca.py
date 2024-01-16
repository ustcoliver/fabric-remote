import subprocess
import os

from utils.log import logger
from env import (
    hosts,
    project_name,
)
from utils.remote import remote_run
from utils.sync import sync_put, sync_get

def generate_crypto():
    for host in hosts:
        logger.info(f"generate crypto by fabric-ca on {host}")
        command = (
            f"cd ~/{project_name} && bash remote-scripts/fabric-ca.sh generate 2>&1"
        )
        remote_run(host, command, _hide=True)

def generate_ccp():
    for host in hosts:
        logger.info(f"generate CCP files for {host}")
        command = f"cd ~/{project_name} && bash remote-scripts/ccp-generate.sh"
        remote_run(host,command)

def ca_container_up():
    """弃用,直接在remote_up中启动fabric-ca容器"""
    for host in hosts:
        command = f"cd ~/{project_name} && bash remote-scripts/fabric-ca.sh up 2>&1"
        remote_run(host, command, _hide=True)

def sync_certs():
    for host in hosts:
        logger.info(f"sync peer crypto from {host}")
        sync_get(host, ["fabric-remote/organizations/peerOrganizations", "fabric-remote/organizations/ordererOrganizations"], "organizations")
    for host in hosts:
        logger.info(f"sync peer crypto to {host}")
        sync_put(host, ["organizations"], "fabric-remote")