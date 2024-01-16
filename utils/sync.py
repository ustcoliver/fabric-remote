from env import channel_profiles, hosts, orgs, project_name, host_count
import os
import subprocess

import logging
from logging.handlers import RotatingFileHandler

# sync过程产生大量不必要log，将其单独保存到其他文件中
# 创建日志对象
logger = logging.getLogger("synclogger")
logger.setLevel(logging.DEBUG)
# 设置日志文件和相关格式
log_folder = "logs"
log_file = os.path.join(log_folder, "sync.log")
file_handler = RotatingFileHandler(
    filename=log_file, maxBytes=1024 * 1025 * 100, backupCount=3
)
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(
    logging.Formatter(
        "%(asctime)s [%(filename)s:%("
        "lineno)d]-[%(funcName)s] %(levelname)s : %(message)s"
    )
)
logger.addHandler(file_handler)


# 同步文件到远程主机
def sync_put(host, local_path_list, remote_path):
    """同步文件到远程主机
    参数：
        host: 远程主机地址
        local_path_list: 本地文件路径列表
        remote_path: 远程文件路径
    """
    local_paths = " ".join(local_path_list)
    logger.info(f"sync {local_paths} to {host}:{remote_path}")
    command = f"rsync -av {local_paths} {host}:{remote_path}"
    logger.info(command)
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    output, error = process.communicate()
    if error:
        logger.error(error.decode())
    else:
        logger.info("sync success")

def sync_get(host, remote_path_list, local_path):
    """从远程主机同步文件到本地
    参数：
        host: 远程主机地址
        remote_path_list: 远程文件路径列表
        local_path: 本地文件路径 
    """
    remote_paths = " ".join(remote_path_list)
    logger.info(f"sync {remote_paths} from {host}:{local_path}")
    command = f"rsync -av {host}:{remote_paths} {local_path}"
    logger.info(command)
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    output, error = process.communicate()
    if error:
        logger.error(error.decode())
    else:
        logger.info("sync success")


# 同步区块链配置到远程主机
def sync_config():
    from utils.log import logger

    for i in range(host_count):
        logger.info(f"sync fabric config to {hosts[i]}")
        sync_put(
            hosts[i],
            [
                "configtx",
                "organizations",
                "system-genesis-block",
                "channel-artifacts",
                "chaincode",
                "scripts",
                "remote-scripts",
                "iphosts",
            ],
            project_name,
        )
        sync_put(
            hosts[i], [f"docker/host{i+1}.yaml"], project_name + "/docker-compose.yaml"
        )
        sync_put(
            hosts[i], [f"envs/host{i+1}.sh"], project_name + "/remote-scripts/env.sh"
        )
