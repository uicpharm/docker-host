#!/bin/bash

version=1.0.0
bold=$(tput bold)
ul=$(tput smul)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
norm=$(tput sgr0)

display_version() {
   hash=$(cat "$0" | sha256sum | cut -c1-8)
   echo "$(basename "$0") version $version build $hash"
}

display_help() {
   cat <<EOF
$bold$(display_version)$norm
${red}UIC Retzky College of Pharmacy$norm

Usage: $(basename "$0") <container or pod name> [OPTIONS]

Creates a system service for a container or pod. The container or pod must be
running. By default, it will restart the container or pod so that systemctl can
track its status. If you don't want it to restart the service, you can use the
option $bold--no-restart$norm, but then systemctl won't work until after an OS restart.

Options:
-h, --help         Show this help message and exit.
-n, --no-restart   Don't restart the container when creating the service.
-V, --version      Print version and exit.
EOF
}

svc_name="$1"
[[ $* =~ -h || $* =~ --help ]] && display_help && exit 1
[[ $* =~ -V || $* =~ --version ]] && display_version && exit 1
[[ $* =~ -n || $* =~ --no-restart ]] && systemctl_opts=() || systemctl_opts=(--now)

# Abort if service was not provided
if [[ -z "$svc_name" ]] || [[ $svc_name == -* ]]; then
   echo -e "${red}You must provide a service name.$norm" >&2
   exit 1
fi

# Only run if we are using podman
if [[ $(podman --version 2>/dev/null) == podman* ]]; then
   (
      cd /etc/systemd/system || exit 1
      echo "Setting up service as $(tput bold)$svc_name$(tput sgr0):"
      podman generate systemd --new --files --pod-prefix= --separator= --container-prefix= --name "$svc_name"
      systemctl daemon-reload
      systemctl enable "$svc_name" "${systemctl_opts[@]}"
      if [[ ${systemctl_opts[*]} != *"--now"* ]]; then
         echo "${yellow}Service was not restarted. You can't use systemctl until a system restart.$norm"
      fi
      echo -e "\nExample usage: ${bold}${ul}systemctl start $svc_name$norm to start the stack.\n"
   )
else
   echo "${red}You don't seem to be using podman. Aborting.$norm" >&2
fi
