#!/bin/bash

SCRIPT_TITLE="Install GitHub Actions runner"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

# Setup a GitHub runner
echo "$(tput bold)
#
# Install GitHub Actions runner...
#
$(tput sgr0)"
sleep 2

# Calculate installer filename based on system
org="uicpharm"
ver="2.314.1"
[ "$(uname)" = 'Linux' ] && os='linux'
[ "$(uname)" = 'Darwin' ] && os='osx'
arch=$(uname -m | sed -e 's/aarch/arm/' -e 's/x86_/x/')
installer_filename="actions-runner-$os-$arch-$ver.tar.gz"

# If we can't find the right OS and arch, abort.
if [ -z "$os" ] || [ -z "$arch" ]; then
   echo 'Could not determine the OS or architecture!'
   exit 1
fi

adduser github
echo Set a password for the new \"github\" user
passwd github
usermod -aG docker github

# Actual installation steps of the github runner
echo "Removing the existing 'actions-runner' directory, if it exists, to start fresh."
runuser -l github -c "\
   rm -Rf actions-runner && \
   mkdir -p actions-runner && \
   cd actions-runner && \
   curl -O -L https://github.com/actions/runner/releases/download/v$ver/$installer_filename && \
   tar xzf ./$installer_filename \
"
sh -c /home/github/actions-runner/bin/installdependencies.sh
echo "Please go to this link and find the token in the 'Configure' section:"
echo "https://github.com/organizations/$org/settings/actions/runners/new?arch=$arch&os=$os"
read -r -p "Type just the token: " tok
runuser -l github -c "cd actions-runner && ./config.sh --url https://github.com/$org --token $tok"
sh -c 'cd /home/github/actions-runner && ./svc.sh install && ./svc.sh start'
echo Done installing GitHub Actions runner!
