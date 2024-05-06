#!/bin/bash

# Set up portainer
echo "$(tput bold)
#
# Installing Portainer as a stack...
#
$(tput sgr0)"
sleep 2
scr_dir="${0%/*}"
# Start the stack
docker-compose -f "$scr_dir"/portainer.yml up -d
# If we're using podman and `podman-install-service` is available, create the systemd service
command -v podman-install-service &> /dev/null && podman-install-service portainer
echo Done installing Portainer!
