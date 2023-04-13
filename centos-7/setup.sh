#!/bin/bash

# Initial OS update
yum clean all && yum makecache
yum update -y
yum install -y epel-release
yum install -y nano htop

# Setup Docker
yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
systemctl enable docker
docker swarm init

# Set up portainer
curl -H 'Cache-Control: no-cache, no-store' -o- https://raw.githubusercontent.com/uicpharm/docker-host/main/aliases >> ~/.bashrc
source ~/.bashrc
pupdate 

# Set up Nginx Proxy Manager
docker network create -d bridge --scope swarm frontend
openssl rand -base64 32 | docker secret create nginxproxymanager_db_password -
openssl rand -base64 32 | docker secret create nginxproxymanager_db_root_password -
read -p "Create a stack in portainer from docker-compose-nginx-proxy-manager.yml and hit a key to continue. "

# Setup a GitHub runner
adduser github
echo Set a password for the new \"github\" user
passwd github
usermod -aG docker github

# Actual installation steps of the github runner
echo "Removing the existing 'actions-runner' directory, if it exists, to start fresh."
runuser -l github -c '\
    rm -Rf actions-runner && \
    mkdir -p actions-runner && \
    cd actions-runner && \
    curl -O -L https://github.com/actions/runner/releases/download/v2.303.0/actions-runner-linux-x64-2.303.0.tar.gz && \
    tar xzf ./actions-runner-linux-x64-2.303.0.tar.gz \
'
sh -c /home/github/actions-runner/bin/installdependencies.sh
echo "Please go to this link and find the token in the 'Configure' section:"
echo "https://github.com/organizations/uicpharm/settings/actions/runners/new?arch=x64&os=linux"
read -p "Type just the token: " tok
runuser -l github -c "cd actions-runner && ./config.sh --url https://github.com/uicpharm --token $tok"
sh -c 'cd /home/github/actions-runner && ./svc.sh install && ./svc.sh start'
