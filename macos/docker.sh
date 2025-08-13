#!/bin/bash

scr_dir=$(realpath "${0%/*}")

SCRIPT_TITLE="Install Docker Desktop"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

eval "$(/opt/homebrew/bin/brew shellenv)"
if which docker &>/dev/null; then
   echo 'Already installed: Docker'
else
   brew install --cask docker
fi
sleep 3
open -a Docker
echo -n 'Waiting for Docker Desktop to start up...'
until docker ps &> /dev/null; do echo -n '.'; sleep 5; done
echo

# Add scripts to /usr/local/bin so it will be in the path
# (On macOS, we must use this one because /usr/bin is not permitted)
if [ -d '/usr/local/bin' ]; then
   bin_dir='/usr/local/bin'
fi
if [ -n "$bin_dir" ]; then
   echo "Installing scripts to $bin_dir may require a password."
   for scr_name in "$scr_dir"/../shared/bin/*.sh; do
      sudo ln -f -s "$(realpath "$scr_name")" "$bin_dir/$(basename "$scr_name" .sh)"
   done
fi
