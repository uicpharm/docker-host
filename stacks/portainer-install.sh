#!/bin/bash

# Set up portainer
echo '
#
# Installing Portainer as a stack...
#
'
sleep 2
scr_dir="${0%/*}"
docker stack deploy -c "$scr_dir"/portainer.yml portainer
echo Done installing Portainer!
