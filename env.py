import os

from utils.log import logger

class FabricOrg:
    def __init__(self, project_name, org_domain, org_name, org_host, org_host_ip):
        self.project_name = project_name
        self.org_domain = org_domain
        self.org_name = org_name
        self.org_addr = f"{org_name}.{org_domain}"
        first_cap_org_name = org_name[0].upper() + org_name[1:]
        self.org_msp = f"{first_cap_org_name}MSP"
        self.org_host = org_host
        self.org_host_ip = org_host_ip

        self.peer_name = []
        self.peer_addr = []
        self.peer_port = []

    def set_peers(self, peer_name, peer_port):
        self.peer_name.append(peer_name)
        self.peer_addr.append(f"{peer_name}.{self.org_addr}")
        self.peer_port.append(peer_port)

    def set_orderer(self, orderer_name, orderer_port):
        self.orderer_name = orderer_name
        self.orderer_addr = f"{orderer_name}.{self.org_domain}"
        self.orderer_port = orderer_port

    def set_channel(self, channel_name, channel_profile):
        self.channel_name = channel_name
        self.channel_profile = channel_profile

    def set_ca(
        self,
        port,
        ca="ca",
    ):
        self.ca_name = f"{ca}.{self.org_addr}"
        self.ca_addr = self.ca_name
        self.ca_container = self.ca_name
        self.ca_port = port

    def generate_env_file(self):
        """为每个主机生成host.sh文件到envs目录下"""
        if not os.path.exists("envs"):
            logger.info("env folder not found, create envs folder")
            os.makedirs("envs")
        logger.info(f"generate env file for {self.org_host}")
        with open(f"envs/{self.org_host}.sh", "w") as f:
            f.write("#!/bin/bash\n")
            f.write(f"PROJECT_NAME={self.project_name}\n")
            f.write(f"ORG_DOMAIN={self.org_domain}\n")
            f.write(f"ORG_NAME={self.org_name}\n")
            f.write(f"ORG_ADDR={self.org_addr}\n")
            f.write(f"ORG_MSP={self.org_msp}\n")
            f.write(f"HOST={self.org_host}\n")
            f.write(f"HOST_IP={self.org_host_ip}\n")

            f.write(f"PEER0_NAME={self.peer_name[0]}\n")
            f.write(f"PEER0_ADDR={self.peer_addr[0]}\n")
            f.write(f"PEER0_PORT={self.peer_port[0]}\n")

            f.write(f"ORDERER_NAME={self.orderer_name}\n")
            f.write(f"ORDERER_ADDR={self.orderer_addr}\n")
            f.write(f"ORDERER_PORT={self.orderer_port}\n")

            f.write(f"CHANNEL={self.channel_name}\n")
            f.write(f"CHANNEL_PROFILE={self.channel_profile}\n")

            f.write(f"CA_NAME={self.ca_name}\n")
            f.write(f"CA_ADDR={self.ca_addr}\n")
            f.write(f"CA_CONTAINER={self.ca_container}\n")
            f.write(f"CA_PORT={self.ca_port}\n")

os_home = "/home/debian"

project_name = "fabric-remote"
project_domain = "remote.com"


channels = ["channel-one", "channel-two"]
channel_profiles = ["ChannelOne", "ChannelTwo"]

host_count = 6

# host_num = [1,2,3,4,5,6]
host_num = [i for i in range(1, host_count + 1)]

# hosts=["host1", "host2", "host3", "host4", "host5", "host6"]
hosts = [f"host{i}" for i in host_num]

# channel_name = ["channel-one", "channel-one,..."]
# 暂时所有节点都加入channel-one
channel_names = ["channel-one"] * 6

channel_profile = ["ChannelOne"] * 6


# host_ip = [10.2.2.11, 10.2.2.12,..]
host_ip = [f"10.2.2.1{i}" for i in host_num]

# orgs=["org1", "org2", "org3", "org4", "org5", "org6"]
orgs = [f"org{i}" for i in host_num]
# org_addresses = ["org1.remote.com", "org2.remote.com", ...]
org_addres = [f"org{i}.{project_domain}" for i in host_num]

# orderer_addresses= ["orderer1.remote.com", "orderer2.remote.com", ....]
orderer_addres = [f"orderer{i}.{project_domain}" for i in host_num]

# peer_addres = ["peer0.org1.remote.com", "peer0.org2.remote.com", ...]
peer_addres = [f"peer0.org{i}.{project_domain}" for i in host_num]

# ca_addres = [ "ca.org1.remote.com", "ca.org2.remote.com", ...]
ca_addres = [f"ca.org{i}.remote.com" for i in host_num]
ca_containers = ca_addres
ca_names = ca_addres

fabric_orgs = []

for i in range(host_count):
    temp_org = FabricOrg(
        project_name,
        org_domain=project_domain,
        org_name=orgs[i],
        org_host=hosts[i],
        org_host_ip=host_ip[i],
    )
    temp_org.set_peers("peer0", 7051)
    temp_org.set_orderer(f"orderer{i+1}", 7050)
    temp_org.set_channel(channel_names[i], channel_profile[i])
    temp_org.set_ca(7054)
    fabric_orgs.append(temp_org)


def generate_env_files(fabric_org_list=fabric_orgs):
    for org in fabric_org_list:
        org.generate_env_file()