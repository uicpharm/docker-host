#!/bin/bash

# Setup a GitHub runner
echo '
#
# Step #3. Installing GitHub Actions runner...
#
'
sleep 2
adduser github
echo Set a password for the new \"github\" user
passwd github
usermod -aG docker github

# Actual installation steps of the github runner
echo "Removing the existing 'actions-runner' directory, if it exists, to start fresh."
runuser -l github -c '\
   rm -Rf actions-runner && \
   mkdir -p actions-runner && \
   cd actions-runner && \
   curl -O -L https://github.com/actions/runner/releases/download/v2.303.0/actions-runner-linux-x64-2.304.0.tar.gz && \
   tar xzf ./actions-runner-linux-x64-2.304.0.tar.gz \
'
sh -c /home/github/actions-runner/bin/installdependencies.sh
echo "Please go to this link and find the token in the 'Configure' section:"
echo "https://github.com/organizations/uicpharm/settings/actions/runners/new?arch=x64&os=linux"
read -r -p "Type just the token: " tok
runuser -l github -c "cd actions-runner && ./config.sh --url https://github.com/uicpharm --token $tok"
sh -c 'cd /home/github/actions-runner && ./svc.sh install && ./svc.sh start'
echo Done installing GitHub Actions runner!
