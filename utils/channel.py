from fabric import Connection
from utils.log import logger
from utils.env import hosts, project_name, project_domain, channels, os_home
from utils.remote import remote_run
import os


def create_channel(channel_name, host_create):
    logger.info(f"create channel {channel_name} on {host_create}...")
    command=f"docker exec -it cli.{project_domain} bash remote-scripts/cli-channel.sh create {channel_name}"
    logger.info(f"command is :\n {command}")
    remote_run(host_create, command)
    
def sync_channel_block(channel_name, host_create, hosts):
    logger.info(f"sync channel tx from {host_create} to {' '.join(hosts)}...")
    with Connection(host_create) as c:
        # 将host_create 主机的channel-artifacts/{channel_name}.block文件复制到本地
        c.get(f"{os_home}/{project_name}/channel-artifacts/{channel_name}.block", f"{os_home}/{project_name}/channel-artifacts/{channel_name}.block")
    # 将本地的channel-artifacts/{channel_name}.block文件复制到host_join_list中的主机
    for host in hosts:
        with Connection(host) as c:
            c.put(f"{os_home}/{project_name}/channel-artifacts/{channel_name}.block", f"{os_home}/{project_name}/channel-artifacts/{channel_name}.block")
    
    
def join_channel(channel_name, hosts):
    command=f"docker exec -it cli.{project_domain} bash remote-scripts/cli-channel.sh join {channel_name}"
    for host in hosts:
        logger.info(f"join channel {channel_name} on {host}...")
        logger.info(f"command is :\n {command}")
        remote_run(host, command)
        
def update_anchor_peer(channel_name, hosts):
    for host in hosts:
        logger.info(f"update anchor peer on {host}...")
        command=f"docker exec -it cli.{project_domain} bash remote-scripts/setAnchorPeer.sh {channel_name}"
        logger.info(f"command is :\n {command}")
        remote_run(host, command)
        
def channel(channel_name,  host_create, hosts):
    create_channel(channel_name, host_create)
    sync_channel_block(channel_name, host_create, hosts)
    join_channel(channel_name, hosts)
    update_anchor_peer(channel_name, hosts)
        