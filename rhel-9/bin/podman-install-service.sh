#!/bin/bash
svc_name="$1"

# Abort if service was not provided
if [[ -z "$svc_name" ]]; then
   echo "Usage: $0 <container or pod name>"
   exit 1
fi

# Only run if "docker" is answering as podman
if [[ $(docker --version) == podman* ]]; then
   (
      cd /etc/systemd/system || exit 1
      echo "Setting up service as $(tput bold)$svc_name$(tput sgr0):"
      podman generate systemd --new --files --pod-prefix= --separator= --container-prefix= --name "$svc_name"
      systemctl daemon-reload
      systemctl enable "$svc_name"
      echo -e "\nExample usage: $(tput bold)$(tput smul)systemctl start $svc_name$(tput sgr0) to start the stack.\n"
   )
fi