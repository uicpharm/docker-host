#!/bin/bash

scr_dir="${0%/*}"

clear
echo '
SETTING UP CENTOS 7 WITH DOCKER AND RELATED TOOLS
=================================================

Hello, I will guide you through the process of setting up your server to host
Docker, installing some standard stacks, and a GitHub Actions Runner.

This installation has multiple incremental steps. You can choose to only
execute part of the installation process if you do not want the later parts.

0) Prep OS with updates'

# This is a little wonky in that this human-readable list is hard-coded and
# must correspond to the script files. But we're keeping it simple.
PS3='How far in the installation process to you want to go? '
select choice in \
   'Install Docker' \
   'Install Stacks' \
   'Install GitHub Actions Runner'; do
   [ "$REPLY" = "0" ] && echo 'Please choose a number higher than Step #0.'
   if [ -z "$choice" ]; then echo 'That is not a valid choice.'; else break; fi
done

scripts=$(ls "$scr_dir"/?-*.sh)
for script in $scripts; do
   scriptnum=$(echo "$script" | sed -e 's/^\.\///' | cut -d'-' -f1)
   [ "$REPLY" -ge "$scriptnum" ] && clear && $script && sleep 5
done
