#!/bin/bash

# Set up portainer
echo '
#
# Installing Portainer as a stack...
#
'
sleep 2
scr_dir="${0%/*}"
mkdir -p "$scr_dir"/../data/portainer
docker stack deploy -c "$scr_dir"/portainer.yml portainer
echo Done installing Portainer!
