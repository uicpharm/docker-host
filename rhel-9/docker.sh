#!/bin/bash

scr_dir=$(realpath "${0%/*}")
[[ -z $DEV ]] && DEV=false

SCRIPT_TITLE="Install Docker/Podman"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

# Standard Install
dnf install -y python-dotenv container-tools podman-compose

# Add scripts to /usr/bin so it will be in the path
if [[ -d /usr/bin ]]; then
   bin_dir=/usr/bin
elif [[ -d /usr/local/bin ]]; then
   bin_dir=/usr/local/bin
fi
if [[ -n $bin_dir ]]; then
   echo "Installing scripts to $(tput smul)$bin_dir$(tput rmul) (may require a password):"
   for scr_name in "$scr_dir"/../shared/bin/*.sh "$scr_dir"/bin/*.sh; do
      cmd=(install -b -v) && $DEV && cmd=(ln -f -v -s)
      cmd+=("$(realpath "$scr_name")")
      cmd+=("$bin_dir/$(basename "$scr_name" .sh)")
      "${cmd[@]}"
   done
else
   echo "$(tput setaf 1)Cannot install scripts to $(tput smul)$bin_dir$(tput rmul) because it wasn't found.$(tput sgr0)" >&2
fi

# Silence Docker emulation messages
touch /etc/containers/nodocker

# Network fix to allow multiple networks associated to a container
# Ref: https://virtualzone.de/posts/podman-multiple-networks/
setting='net.ipv4.conf.all.rp_filter=2'
sysctl -w "$setting"
grep -q "$setting" /etc/sysctl.conf || echo "$setting" >> /etc/sysctl.conf

# SELinux setting for systemd service creation
setsebool -P container_manage_cgroup on

# Start/Enable Docker
systemctl enable --now podman

echo Done installing Docker!
