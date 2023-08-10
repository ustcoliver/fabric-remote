import subprocess
import os
from utils.log import logger
from utils.env import channels, channel_profiles, hosts, orgs, project_name

def generate_crypto():
    # 如果不存在organizations文件夹，则生成crypto文件
    if not os.path.exists('organizations'):
        logger.info("generate crypto files")
        pwd = os.getcwd()
        config_file = os.path.join(pwd, "configtx/orgs.yaml")
        output_dir = os.path.join(pwd, "organizations")
        command = f"cryptogen generate --config={config_file} --output={output_dir}"
        logger.info(command)
        process=subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, error = process.communicate()
        # 如果有错误信息，打印错误信息
        if error:
            logger.error(error)
        else:
            logger.info("output is \n"+output.decode())
    # 如果存在organizations文件夹，提示已经存在
    else:
        logger.info("crypto files already exists, pass")
        
def generate_channel(profile, channel_id, output_file):

    pwd=os.getcwd()
    config_path = os.path.join(pwd, "configtx")
    command=""
    # 根据channel_id判断是创建系统通道还是应用通道
    if channel_id == "system-channel":
        # 如果不存在system-genesis-block文件夹，则生成system-genesis-block文件夹
        if not os.path.exists('system-genesis-block'):
            logger.info("generate system genesis block")
            output_block = os.path.join(pwd, "system-genesis-block", output_file)
            # 如果是创建系统通道，则使用outputBlock
            command = f"configtxgen -configPath {config_path} -profile {profile} -channelID {channel_id} -outputBlock {output_block}"
    else:
        logger.info(f"generate channel tx for {channel_id}")  
        output_channel_tx = os.path.join(pwd, "channel-artifacts", output_file)
        # 如果是创建应用通道，则使用outputCreateChannelTx
        command = f"configtxgen -configPath {config_path} -profile {profile} -channelID {channel_id} -outputCreateChannelTx {output_channel_tx}"
    # 输出要执行的命令内容
    logger.info(command)
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()
    # 如果有错误信息，打印错误信息
    # 这里configtxgen存在bug，将正常日志输出到了stderr，所以无论如何都要输出error
    logger.info("output is \n" + error.decode())
    # print(error.decode())
    
# 删除crypto文件和通道配置文件
def clean_config():
    logger.info("clean crypto files and fabric config files")
    command = f"bash scripts/remove.sh file organizations channel-artifacts system-genesis-block"
    logger.info(f"command is :\n{command}")
    process= subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()
    if error:
        logger.error(error.decode())
    else:
        logger.info("clean success")
    
# 汇总上述功能，生成crypto文件和通道文件
def local_generate():
    generate_crypto()
    generate_channel("SystemChannel", "system-channel", "genesis.block")
    for i in range(len(channels)):
        generate_channel(channel_profiles[i], channels[i], f"{channels[i]}.tx")
