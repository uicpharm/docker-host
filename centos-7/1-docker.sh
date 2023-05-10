#!/bin/bash

# Setup Docker
echo '
#
# Step #1. Installing Docker...
#
'
sleep 2

# Standard Install
yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Open up firewall for swarm
if [ -n "$(command -v ufw)" ]; then
   echo Opening up ports with ufw...
   ufw allow 2376/tcp
   ufw allow 2377/tcp
   ufw allow 7946/tcp
   ufw allow 7946/udp
   ufw allow 4789/udp
   ufw reload
elif [ -n "$(command -v firewall-cmd)" ]; then
   echo Opening up ports with firewall-cmd...
   firewall-cmd --add-port=2376/tcp --permanent
   firewall-cmd --add-port=2377/tcp --permanent
   firewall-cmd --add-port=7946/tcp --permanent
   firewall-cmd --add-port=7946/udp --permanent
   firewall-cmd --add-port=4789/udp --permanent
   firewall-cmd --reload
fi

# Start/Enable Docker
systemctl start docker
systemctl enable docker

# Create a `docker` user. A `docker` group is created during installation.
useradd -M -g docker -u 1001 docker

# Either init or join a swarm
PS3="What cluster action will this server perform? "
select action in "Initialize a Swarm" "Join a Swarm"; do
   if [ -z "$action" ]; then echo "'$REPLY' is not a choice."; else break; fi
done
if [ "$REPLY" = "1" ]; then
   docker swarm init && \
   docker swarm join-token manager && \
   echo IMPORTANT: Copy the command above. You will paste it to the other nodes. && \
   echo -n "Hit enter when ready to proceed. " && \
   read -r
else
   echo -n "Please paste the join command provided by the first node: "
   read -r cmd
   eval "$cmd"
fi

echo "Please provide credentials to $(tput smul)ghcr.io/uicpharm$(tput sgr0) for future projects to download images."
sudo docker login ghcr.io/uicpharm

echo Done installing Docker!
