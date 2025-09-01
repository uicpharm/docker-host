#!/bin/bash

# Set up Nginx Proxy Manager
echo "$(tput bold)
#
# Installing Nginx Proxy Manager as a stack...
#
$(tput sgr0)"
sleep 2
scr_dir=$(realpath "$(dirname "$0")")
[[ -z $DEV ]] && DEV=false

# Determine target directory and install
target_dir=/etc/nginxproxymanager
[[ "$(uname)" == "Darwin" || $EUID -ne 0 ]] && target_dir=$HOME/.nginxproxymanager
$DEV && target_dir=$scr_dir
sec_dir="$target_dir/secrets"
yml_file="$target_dir/nginx-proxy-manager.yml"
if ! $DEV; then
   install -d "$sec_dir"
   install -b "$scr_dir/nginx-proxy-manager.yml" "$yml_file"
fi
[[ $* == -u || $* == --upgrade ]] && upgrade_args=(--pull always)
# Set up common "frontend" network shared among containers
[ -z "$(docker network ls -qf name=frontend)" ] && docker network create frontend
# Secrets for the passwords
[ ! -f "$sec_dir/db_password.txt" ] && openssl rand -hex 32 > "$sec_dir/db_password.txt"
[ ! -f "$sec_dir/db_root_password.txt" ] && openssl rand -hex 32 > "$sec_dir/db_root_password.txt"
# If we're using podman, create the pod and include the podman arguments
svc_name="nginxproxymanager"
(
   cd "$target_dir" || exit 1
   if [[ $(podman --version 2>/dev/null) == podman* ]]; then
      podman pod create --name "$svc_name"
      podman-compose --in-pod "$svc_name" --podman-run-args "${upgrade_args[*]}" -f "$yml_file" up -d
   else
      docker compose -f "$yml_file" up -d "${upgrade_args[@]}"
   fi
)
# If we're using podman and `podman-install-service` is available, create the systemd service
command -v podman-install-service &> /dev/null && podman-install-service "$svc_name"
echo Done installing Nginx Proxy Manager!
