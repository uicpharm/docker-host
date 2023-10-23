#!/bin/bash

# Set up Nginx Proxy Manager
echo '
#
# Installing Nginx Proxy Manager as a stack...
#
'
sleep 2
scr_dir="${0%/*}"
[ -z "$(docker network ls -qf name=frontend)" ] && docker network create -d overlay --scope swarm --attachable frontend
[ -z "$(docker secret ls -qf name=nginxproxymanager_db_password)" ] && openssl rand -base64 32 | docker secret create nginxproxymanager_db_password -
[ -z "$(docker secret ls -qf name=nginxproxymanager_db_root_password)" ] && openssl rand -base64 32 | docker secret create nginxproxymanager_db_root_password -
docker stack deploy -c "$scr_dir"/nginx-proxy-manager.yml nginxproxymanager
echo Done installing Nginx Proxy Manager!
