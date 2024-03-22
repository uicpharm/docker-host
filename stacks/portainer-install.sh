#!/bin/bash

# Set up portainer
echo "$(tput bold)
#
# Installing Portainer as a stack...
#
$(tput sgr0)"
sleep 2
scr_dir="${0%/*}"
docker-compose -f "$scr_dir"/portainer.yml up -d
echo Done installing Portainer!
