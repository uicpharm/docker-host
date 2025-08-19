#!/bin/bash

SCRIPT_TITLE="Updating OS packages and prepare the system"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

apt update && apt upgrade -y
apt install -y bzip2 curl htop jq nano rsync
echo Done updating OS packages!
