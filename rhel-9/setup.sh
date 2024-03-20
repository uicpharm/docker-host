#!/bin/bash

scr_dir="${0%/*}"

clear
echo "$(tput bold)$(tput smul)
SETTING UP RED HAT 9 FOR CONTAINERIZATION
$(tput sgr0)
Hello, I will guide you through the process of setting up your server to host
a containerized application and related tooling. Since Docker isn't supported
on RHEL 9, the Podman tooling will be installed along with related Docker
compatibility packages.

This installation has multiple incremental steps. You can choose to only
execute part of the installation process if you do not want the later parts.
"

"$scr_dir/setup-shared.sh"
