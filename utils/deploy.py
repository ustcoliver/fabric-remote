from utils.remote import remote_run
from utils.log import logger
from fabric import Connection
from env import project_domain, project_name, os_home
import subprocess


def prepare_chaincode(chaincode_path):
    command = f"cd {chaincode_path} &&  GO111MODULE=on go mod vendor"
    logger.info(f"prepare the chaincode on local")
    logger.info(f"command is :\n{command}")
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    output, error = process.communicate()
    if process.returncode != 0:
        logger.error(f"prepare chaincode error: {error}")
        exit(1)


# 打包链码
def package_chaincode(chaincode_name, chaincode_path, host_package):
    logger.info(f"package chaincode {chaincode_name} on {host_package}...")
    command = f"docker exec -it cli.{project_domain} bash remote-scripts/cli-deployCC.sh package {chaincode_name} {chaincode_path}"
    logger.info(f"command is :\n {command}")
    remote_run(host_package, command)


# 将打包后的链码同步其他主机
def sync_chaincode_package(chaincode_name, host_package, host_sync_list):
    logger.info(
        f"sync {chaincode_name} package from {host_package} to {' '.join(host_sync_list)}..."
    )
    command = f"docker cp cli.{project_domain}:/opt/gopath/src/github.com/hyperledger/fabric/peer/{chaincode_name}.tar.gz {os_home}/{project_name}/{chaincode_name}.tar.gz"
    remote_run(host_package, command)
    with Connection(host_package) as c:
        c.get(
            f"{os_home}/{project_name}/{chaincode_name}.tar.gz",
            f"{os_home}/{project_name}/{chaincode_name}.tar.gz",
        )
    for host in host_sync_list:
        with Connection(host) as c:
            c.put(
                f"{os_home}/{project_name}/{chaincode_name}.tar.gz",
                f"{os_home}/{project_name}/{chaincode_name}.tar.gz",
            )
        command = f"docker cp {os_home}/{project_name}/{chaincode_name}.tar.gz cli.{project_domain}:/opt/gopath/src/github.com/hyperledger/fabric/peer/{chaincode_name}.tar.gz"
        remote_run(host, command)


# 在host_install_list上为相应的org安装链码
def install_chaincode(
    channel_name, chaincode_name, host_install_list, org_install_list
):
    for i in range(len(host_install_list)):
        host = host_install_list[i]
        org = org_install_list[i]
        command = f"docker exec -it cli.{project_domain} bash remote-scripts/cli-deployCC.sh install {chaincode_name} {channel_name} {org}"
        logger.info(f"install chaincode {chaincode_name} for {host} on {host}...")
        logger.info(f"command is :\n {command}")
        remote_run(host, command)


def commit_chaincode(channel_name, chaincode_name, host_package, org_commit_list):
    command = f"docker exec -it cli.{project_domain} bash remote-scripts/cli-deployCC.sh commit {chaincode_name} {channel_name} {' '.join(org_commit_list)}"
    logger.info(f"commit chaincode {chaincode_name} on {host_package}...")
    logger.info(f"command is :\n {command}")
    remote_run(host_package, command)


def query_chaincode_commitment(
    channel_name, chaincode_name, host_query_list, org_query_list
):
    for i in range(len(host_query_list)):
        host = host_query_list[i]
        org = org_query_list[i]
        command = f"docker exec -it cli.{project_domain} bash remote-scripts/cli-deployCC.sh query-commit {chaincode_name} {channel_name} {org}"
        logger.info(
            f"query chaincode {chaincode_name} commitment for {org} on {host}..."
        )
        logger.info(f"command is :\n {command}")
        remote_run(host, command)


def init_chaincode(channel_name, chaincode_name, host_package, org_init_list):
    command = f"docker exec -it cli.{project_domain} bash remote-scripts/cli-deployCC.sh init {chaincode_name} {channel_name} {' '.join(org_init_list)}"
    logger.info(f"init chaincode {chaincode_name} on {host_package}...")
    logger.info(f"command is :\n {command}")
    remote_run(host_package, command)


def query_chaincode(channel_name, chaincode_name, host_query, org_query, query_args):
    command = f"docker exec -it cli.{project_domain} bash remote-scripts/cli-deployCC.sh query {chaincode_name} {channel_name} {org_query} {query_args}"
    logger.info(f"query chaincode {chaincode_name} for {org_query} on {host_query}...")
    logger.info(f"command is :\n {command}")
    remote_run(host_query, command)


def query_chaincode_all(
    channel_name, chaincode_name, host_query_list, org_query_list, query_args
):
    for i in range(len(host_query_list)):
        host = host_query_list[i]
        org = org_query_list[i]
        query_chaincode(channel_name, chaincode_name, host, org, query_args)


def deploy_chaincode(
    channel_name, chaincode_name, chaincode_path, host_package, hosts, orgs, query_args
):
    # prepare_chaincode(chaincode_path)
    package_chaincode(chaincode_name, chaincode_path, host_package)
    sync_chaincode_package(chaincode_name, host_package, hosts)
    install_chaincode(channel_name, chaincode_name, hosts, orgs)
    commit_chaincode(channel_name, chaincode_name, host_package, orgs)
    query_chaincode_commitment(channel_name, chaincode_name, hosts, orgs)
    init_chaincode(channel_name, chaincode_name, host_package, orgs)
    query_chaincode_all(channel_name, chaincode_name, hosts, orgs, query_args)


def invoke_chaincode(
    channel_name, chaincode_name, host_invoke, org_invoke, invoke_args
):
    command = f"docker exec -it cli.{project_domain} bash remote-scripts/cli-deployCC.sh invoke {chaincode_name} {channel_name} {org_invoke} {invoke_args}"
    logger.info(
        f"invoke chaincode {chaincode_name} for {org_invoke} on {host_invoke}..."
    )
    logger.info(f"command is :\n {command}")
    remote_run(host_invoke, command)
