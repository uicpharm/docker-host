#!/bin/bash

SCRIPT_TITLE="Install Docker Desktop"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

eval "$(/opt/homebrew/bin/brew shellenv)"
brew install --cask docker
brew install docker-compose
sleep 3
open -a Docker
echo -n 'Waiting for Docker Desktop to start up...'
sleep 20
until docker ps &> /dev/null; do echo -n '.'; sleep 5; done
