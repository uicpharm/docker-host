#!/bin/bash

scr_dir=$(realpath "${0%/*}")

SCRIPT_TITLE="Install Docker"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

# Standard Install
yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Open up firewall for Docker daemon
if [ -n "$(command -v ufw)" ]; then
   echo Opening up ports with ufw...
   ufw allow 2376/tcp
   ufw reload
elif [ -n "$(command -v firewall-cmd)" ]; then
   echo Opening up ports with firewall-cmd...
   firewall-cmd --add-port=2376/tcp --permanent
   firewall-cmd --reload
fi

# Add scripts to /usr/bin so it will be in the path
if [ -d '/usr/bin' ]; then
   bin_dir='/usr/bin'
elif [ -d '/usr/local/bin' ]; then
   bin_dir='/usr/local/bin'
fi
if [ -n "$bin_dir" ]; then
   ln -f -s "$(realpath "$scr_dir/../shared/bin/deploy.sh")" "$bin_dir/deploy"
fi

# Start/Enable Docker
systemctl enable --now docker

# Create a `docker` user. A `docker` group is created during installation.
useradd -M -g docker -u 1001 docker

echo Done installing Docker!
