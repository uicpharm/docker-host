#!/bin/bash

scr_dir=$(realpath "${0%/*}")

SCRIPT_TITLE="Install Docker/Podman"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

# Standard Install
dnf install -y container-tools podman-compose

# Add scripts to /usr/bin so it will be in the path
if [ -d '/usr/bin' ]; then
   bin_dir='/usr/bin'
elif [ -d '/usr/local/bin' ]; then
   bin_dir='/usr/local/bin'
fi
if [ -n "$bin_dir" ]; then
   ln -f -s "$(realpath "$scr_dir/../shared/bin/deploy.sh")" "$bin_dir/deploy"
   ln -f -s "$scr_dir/bin/docker-compose.sh" "$bin_dir/docker-compose"
   ln -f -s "$scr_dir/bin/podman-install-service.sh" "$bin_dir/podman-install-service"
fi

# Silence Docker emulation messages
touch /etc/containers/nodocker

# Network fix to allow multiple networks associated to a container
# Ref: https://virtualzone.de/posts/podman-multiple-networks/
sysctl -w net.ipv4.conf.all.rp_filter=2
echo "net.ipv4.conf.all.rp_filter=2" >> /etc/sysctl.conf

# SELinux setting for systemd service creation
setsebool -P container_manage_cgroup on

# Start/Enable Docker
systemctl enable --now podman

echo Done installing Docker!
