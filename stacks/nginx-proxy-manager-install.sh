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
# Collect user groups
real_user=${SUDO_USER:-$(whoami)}
groups_file=$(mktemp)
(id "$real_user" | cut -d'=' -f4 | tr ',' '\n' > "$groups_file") &
groups_pid="$!"
# Set up common "frontend" network shared among containers
[ -z "$(docker network ls -qf name=frontend)" ] && docker network create frontend
# Secrets for the passwords
mkdir -p "$sec_dir"
[ ! -f "$sec_dir/nginxproxymanager_db_password.txt" ] && openssl rand -hex 32 > "$sec_dir/nginxproxymanager_db_password.txt"
[ ! -f "$sec_dir/nginxproxymanager_db_root_password.txt" ] && openssl rand -hex 32 > "$sec_dir/nginxproxymanager_db_root_password.txt"
# Set strict permissions for the secrets
echo "It is highly recommended that you restrict permissions of the $(tput smul)$(basename "$sec_dir")$(tput rmul) directory."
echo "I can set the group to something your $real_user user also has access to."
read -r -p "Do you want to do this? [Y/n] " yorn
if [[ ${yorn:-y} =~ [Yy] ]]; then
   echo -n "Great! Finding your user groups."
   while ps "$groups_pid" > /dev/null; do echo -n '.'; sleep 1; done
   echo -e '\n'
   while IFS=$'\n' read -r line; do
      group_array+=("$line")
   done <<< "$(<"$groups_file")"
   PS3="Either enter a number or manually type a group name: "
   select group in "${group_array[@]}"; do
      # Accept either the selected group or the manually-entered group
      group=${group:-$REPLY}
      # Don't accept a blank entry
      [[ -n $group ]] && break
   done
   echo "Setting the group of the $(tput smul)$(basename "$sec_dir")$(tput rmul) directory to $(tput smul)$group$(tput rmul)."
   # Groups will look like "123(group_name)", so we get just the number by looking to the left of '('.
   # This will also work with manually entered groups like "group_name" or "123".
   group=$(echo "$group" | cut -d'(' -f1)
   chgrp -R "$group" "$sec_dir"
   chmod -R 770 "$sec_dir"
fi
# If we're using podman, create the pod and include the podman arguments
svc_name="nginxproxymanager"
if [[ $(docker --version) == podman* ]]; then
   podman pod create --name "$svc_name"
   podman-compose --podman-run-args "--pod $svc_name ${upgrade_args[*]}" -f "$yml_file" up -d
else
   docker-compose -f "$yml_file" up -d "${upgrade_args[@]}"
fi
# If we're using podman and `podman-install-service` is available, create the systemd service
command -v podman-install-service &> /dev/null && podman-install-service "$svc_name"
echo Done installing Nginx Proxy Manager!
