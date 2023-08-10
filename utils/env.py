os_home="/home/debian"
project_name="fabric-remote"
project_domain="remote.com"
channels=[ "channel-one", "channel-two"]
channel_profiles = ["ChannelOne", "ChannelTwo"]

hosts=["f1", "f2", "f3", "f4", "f5", "f6"]

orgs=["org1", "org2", "org3", "org4", "org5", "org6"]

orderer_addresses= [f"orderer{i}.{project_domain}:7050" for i in range(1, len(hosts))]
