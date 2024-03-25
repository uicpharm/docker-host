#!/bin/bash

scr_dir="${0%/*}"

SCRIPT_TITLE="Install Docker/Podman"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

# Standard Install
dnf install -y container-tools podman-compose

# Add docker-compose alias for podman-compose
cp "$scr_dir/bin/docker-compose" /usr/bin

# Silence Docker emulation messages
touch /etc/containers/nodocker

# Start/Enable Docker
systemctl enable --now podman

echo Done installing Docker!
