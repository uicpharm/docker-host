#!/bin/bash

# Set up Nginx Proxy Manager
echo "$(tput bold)
#
# Installing Nginx Proxy Manager as a stack...
#
$(tput sgr0)"
sleep 2
scr_dir="${0%/*}"
sec_dir="$scr_dir/../secrets"
yml_file="$scr_dir/nginx-proxy-manager.yml"
[[ $* == -u || $* == --upgrade ]] && upgrade_args=(--pull always)
mkdir -p "$sec_dir"
# Set up common "frontend" network shared among containers
[ -z "$(docker network ls -qf name=frontend)" ] && docker network create frontend
# Secrets for the passwords
[ ! -f "$sec_dir/nginxproxymanager_db_password.txt" ] && openssl rand -hex 32 > "$sec_dir/nginxproxymanager_db_password.txt"
[ ! -f "$sec_dir/nginxproxymanager_db_root_password.txt" ] && openssl rand -hex 32 > "$sec_dir/nginxproxymanager_db_root_password.txt"
# If we're using podman, create the pod and include the podman arguments
svc_name="nginxproxymanager"
if [[ $(docker --version) == podman* ]]; then
   podman pod create --name "$svc_name"
   podman-compose --podman-run-args "--pod $svc_name ${upgrade_args[*]}" -f "$yml_file" up -d
else
   docker compose -f "$yml_file" up -d "${upgrade_args[@]}"
fi
# If we're using podman and `podman-install-service` is available, create the systemd service
command -v podman-install-service &> /dev/null && podman-install-service "$svc_name"
echo Done installing Nginx Proxy Manager!
