#!/bin/bash

scr_dir=$(realpath "${0%/*}")

SCRIPT_TITLE="Install Docker"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

# Standard Install steps prescribed by Docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
# shellcheck disable=SC1091
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add scripts to /usr/bin so it will be in the path
if [ -d '/usr/bin' ]; then
   bin_dir='/usr/bin'
elif [ -d '/usr/local/bin' ]; then
   bin_dir='/usr/local/bin'
fi
if [ -n "$bin_dir" ]; then
   for scr_name in "$scr_dir"/../shared/bin/*.sh; do
      ln -f -s "$(realpath "$scr_name")" "$bin_dir/$(basename "$scr_name" .sh)"
   done
fi

echo Done installing Docker!
