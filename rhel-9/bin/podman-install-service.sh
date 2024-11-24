#!/bin/bash

bold=$(tput bold)
ul=$(tput smul)
red=$(tput setaf 1)
norm=$(tput sgr0)

display_help() {
   cat <<EOF
Usage: $(basename "$0") <container or pod name> [OPTIONS]

Creates a system service for a container or pod. The container or pod must be
running. By default, it will restart the container or pod so that systemctl can
track its status. If you don't want it to restart the service, you can use the
option $bold--no-restart$norm, but then systemctl won't work until after an OS restart.

Options:
-h, --help         Show this help message and exit.
-n, --no-restart   Don't restart the container when creating the service.
EOF
}

svc_name="$1"
[[ $* =~ -h || $* =~ --help ]] && display_help && exit
[[ $* =~ -n || $* =~ --no-restart ]] && systemctl_opts=() || systemctl_opts=(--now)

# Abort if service was not provided
if [[ -z "$svc_name" ]] || [[ $svc_name == -* ]]; then
   echo -e "${red}You must provide a service name.$norm\n" >&2
   display_help
   exit 1
fi

# Only run if "docker" is answering as podman
if [[ $(docker --version) == podman* ]]; then
   (
      cd /etc/systemd/system || exit 1
      echo "Setting up service as $(tput bold)$svc_name$(tput sgr0):"
      podman generate systemd --new --files --pod-prefix= --separator= --container-prefix= --name "$svc_name"
      systemctl daemon-reload
      systemctl enable "$svc_name" "${systemctl_opts[@]}"
      if [[ ${systemctl_opts[*]} != *"--now"* ]]; then
         echo "${red}Service was not restarted. You can't use systemctl until a system restart.$norm"
      fi
      echo -e "\nExample usage: ${bold}${ul}systemctl start $svc_name$norm to start the stack.\n"
   )
else
   echo "${red}You don't seem to be using podman. Aborting.$norm" >&2
fi
