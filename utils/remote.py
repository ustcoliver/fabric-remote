from fabric import Connection
from utils.log import logger
from env import hosts, project_name, project_domain
import os
from utils.sync import sync_config


def remote_run_old(host, command):
    """弃用"""
    with Connection(host) as c:
        try:
            logger.info(f"remote run command on {host} :\n {command}")
            res = c.run(command, pty=True, warn=True)
        except Exception as e:
            logger.error(f"remote run command error: {e}")
            return False
        return True


def remote_run(host, command, _hide=False, success_output=None, error_output=None):
    """远程执行命令,输出stdout和stderr,根据success_output和error_output判断是否成功
    :param host: 主机地址
    :param command: 执行命令
    :param success_output: 成功输出
    :param error_output: 失败输出
    """
    with Connection(host) as c:
        try:
            logger.info(f"remote run command on {host}:\n{command}")
            res = c.run(command, pty=True, warn=True, hide=_hide)
            if _hide:
                logger.debug(res.stdout.strip())
            stdout = res.stdout.strip()
            if success_output and success_output in stdout:
                logger.info("remote run successfully")
            if error_output and error_output in stdout:
                logger.error("remote run failed:\n" + stdout)
        except Exception as e:
            logger.error(f"remote run command error: {e}")


def remote_remove(host, path_list):
    """弃用,直接使用scripts/utils.sh中的RemoveFiles函数删除文件"""
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

def remote_get(host, remote_path, local_path):
    """从远程主机下载文件"""
    with Connection(host) as c:
        c.get(remote_path, local_path)
        
def remote_put(host, local_path, remote_path):
    """上传文件到远程主机"""
    with Connection(host) as c:
        c.put(local_path, remote_path)

def remote_init():
    """初始化项目
    step1: 同步配置文件
    step2: 在所有主机上执行remote.sh init,即创建chaincode和添加iphost
    step3: 在所有主机上执行fabric-ca.sh up,即启动fabric-ca容器
    """
    sync_config()
    for host in hosts:
        logger.info(f"init project on {host}")
        command = f"cd ~/{project_name} && bash remote-scripts/remote.sh init"
        remote_run(host, command, _hide=True)
        logger.info(f"bring up fabric-ca container on {host}")
        command = f"cd ~/{project_name} && bash remote-scripts/fabric-ca.sh up 2>&1"
        remote_run(host, command, _hide=True)


# 远程启动fabric网络
def remote_up():
    for host in hosts:
        logger.info(f"start docker containers on {host}...")
        command = (
            f"cd ~/{project_name} && docker-compose -f docker-compose.yaml up -d"
        )
        remote_run(host, command)


def remote_down():
    """关闭fabric网络, 包括停止docker容器和删除所有文件,通过remote.sh down实现"""
    for host in hosts:
        logger.info(f"bring down the hyperledger fabric network on {host}...")
        command = f"cd ~/{project_name} &&  bash remote-scripts/remote.sh down"
        remote_run(host, command, _hide=True)
