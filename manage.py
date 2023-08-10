import os 
import argparse

from utils.log import logger
from utils.env import hosts,channels, channel_profiles, orgs, project_name 
from utils.generate import local_generate, clean_config
from utils.sync import sync_config
from utils.remote import remote_down,remote_up
from utils.channel import channel
from utils.deploy import deploy_chaincode


if __name__ == "__main__":
    # 处理命令行参数
    parser = argparse.ArgumentParser(description="project command")
    parser.add_argument('command', choices=['up', 'sync','down', 'clean', 'channel', 'start', 'restart','deploy', 'rerun'], help="project start or stop")
    args = parser.parse_args()
    if args.command == "up":
        local_generate()
        sync_config()
        remote_up()
    elif args.command == "sync":
        sync_config()
    elif args.command == "down":
        remote_down()
    elif args.command == "clean":
        clean_config()
    elif args.command == "channel":
        channel("channel-one", hosts[0], hosts)
        channel("channel-two", hosts[1], hosts)
    elif args.command == "start":
        local_generate()
        sync_config()
        remote_up()        
        channel("channel-one", hosts[0], hosts)
        channel("channel-two", hosts[1], hosts)
    elif args.command == "restart":
        remote_down()
        local_generate()
        sync_config()
        remote_up()        
        channel("channel-one", hosts[0], hosts)
        channel("channel-two", hosts[1], hosts)
    elif args.command == "deploy":
        deploy_chaincode("channel-one", "basic", "../chaincode/asset-transfer-basic", "f1", hosts, [str(i) for i in range(1,7)], "GetAllAssets")
    elif args.command == "rerun":
        remote_down()
        local_generate()
        sync_config()
        remote_up()        
        channel("channel-one", hosts[0], hosts)
        channel("channel-two", hosts[1], hosts)
        deploy_chaincode("channel-one", "basic", "../chaincode/asset-transfer-basic", "f1", hosts, [str(i) for i in range(1,7)], "GetAllAssets")
