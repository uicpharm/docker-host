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
mkdir -p "$sec_dir"
[ -z "$(docker network ls -qf name=frontend)" ] && docker network create frontend
[ ! -f "$sec_dir/nginxproxymanager_db_password.txt" ] && openssl rand -hex 32 > $sec_dir/nginxproxymanager_db_password.txt
[ ! -f "$sec_dir/nginxproxymanager_db_root_password.txt" ] && openssl rand -hex 32 > $sec_dir/nginxproxymanager_db_root_password.txt
docker-compose -f "$scr_dir"/nginx-proxy-manager.yml up -d
echo Done installing Nginx Proxy Manager!
