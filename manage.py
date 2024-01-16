import os
import argparse

from utils.log import clear_logs
from env import (
    generate_env_files,
    hosts,
)
from utils.generate import local_generate, clean_config, generate_channel
from utils.generate_ca import generate_crypto, sync_certs
from utils.sync import sync_config
from utils.remote import remote_init, remote_down, remote_up
from utils.channel import channel
from utils.deploy import deploy_chaincode


if __name__ == "__main__":
    # 处理命令行参数
    parser = argparse.ArgumentParser(description="project command")
    parser.add_argument(
        "commands",
        nargs="+",
        choices=[
            "init",
            "generate",
            "ccp",
            "up",
            "sync",
            "down",
            "clean",
            "channel",
            "start",
            "restart",
            "deploy",
            "rerun",
        ],
        help="project start or stop",
    )
    args = parser.parse_args()

    for command in args.commands:
        if command == "up":
            remote_up()
        elif command == "init":
            generate_env_files()
            remote_init()
        elif command == "sync":
            sync_config()
        elif command == "down":
            remote_down()
        elif command == "generate":
            generate_crypto()
            sync_certs()
        elif command == "clean":
            clear_logs()
        elif command == "channel":
            channel("channel-one", hosts[0], hosts)
            channel("channel-two", hosts[1], hosts)
        elif command == "start":
            local_generate()
            sync_config()
            remote_up()
            channel("channel-one", hosts[0], hosts)
        elif command == "restart":
            remote_down()
            local_generate()
            sync_config()
            remote_up()
            channel("channel-one", hosts[0], hosts)
            channel("channel-two", hosts[1], hosts)
        elif command == "deploy":
            deploy_chaincode(
                "channel-one",
                "basic",
                "../chaincode/asset-transfer-basic",
                "f1",
                hosts,
                [str(i) for i in range(1, 7)],
                "GetAllAssets",
            )
        elif command == "rerun":
            remote_down()
            local_generate()
            sync_config()
            remote_up()
            channel("channel-one", hosts[0], hosts)
            channel("channel-two", hosts[1], hosts)
            deploy_chaincode(
                "channel-one",
                "basic",
                "../chaincode/asset-transfer-basic",
                "f1",
                hosts,
                [str(i) for i in range(1, 7)],
                "GetAllAssets",
            )
