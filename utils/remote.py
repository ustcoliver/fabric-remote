from fabric import Connection
from utils.log import logger
from utils.env import hosts, project_name, project_domain
import os
# 远程执行命令
def remote_run(host, command):
    with Connection(host) as c:
        try:
            logger.info(f"remote run command on {host} :\n {command}")
            res = c.run(command, pty=True, warn=True)
        except Exception as e:
            logger.error(f"remote run command error: {e}")
            return False
        return True
        
def remote_remove(host, path_list):
    logger.info(f"remove {','.join(path_list)} on {host}")
    with Connection(host) as c:
        for p in path_list:
            # 拼接路径
            fp = os.path.join("{os_home}", project_name, p)
            # 验证路径文件是否存在
            if c.exists(fp):
                # 如果存在，删除
                c.run(f"rm -rf {fp}")
            else:
                # 如果不存在
                logger.info(f"{fp} not exist on {host}, skip ...")
            
# 远程启动fabric网络           
def remote_up():
    for host in hosts:
        logger.info(f"start docker containers on {host}...")
        command=f"cd {project_name} && docker-compose -f docker-compose-up.yaml up -d"
        remote_run(host, command)
        
# 远程关闭fabric网络，并删除所有文件
def remote_down():
    for host in hosts:
        # 关闭所有docker容器并删除network和volumes
        logger.info(f"remove docker containers on {host}...")
        command=f"cd ~/{project_name} &&  bash scripts/remove.sh docker {project_domain}"
        remote_run(host,command)
        
        # 删除所有配置文件      
        logger.info(f"remove all config on {host}...")
        command=f"cd ~/{project_name} && bash scripts/remove.sh file docker-compose-up.yaml config organizations system-genesis-block channel-artifacts chaincode scripts"
        remote_run(host,command)