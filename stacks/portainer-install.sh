#!/bin/bash

# Set up portainer
echo "$(tput bold)
#
# Installing Portainer as a stack...
#
$(tput sgr0)"
sleep 2
scr_dir="${0%/*}"
yml_file="$scr_dir/portainer.yml"
[[ $* == -u || $* == --upgrade ]] && upgrade_args=(--pull always)
# Start the stack
svc_name="portainer"
if [[ $(docker --version) == podman* ]]; then
   podman pod create --name "$svc_name"
   podman-compose --in-pod "$svc_name" --podman-run-args "${upgrade_args[*]}" -f "$yml_file" up -d
else
   docker compose -f "$yml_file" up -d "${upgrade_args[@]}"
fi
# If we're using podman and `podman-install-service` is available, create the systemd service
command -v podman-install-service &> /dev/null && podman-install-service "$svc_name"
echo Done installing Portainer!
