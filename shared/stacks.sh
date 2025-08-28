#!/bin/bash

scr_dir=$(realpath "$(dirname "$0")")

SCRIPT_TITLE="Install configured stacks"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

"$scr_dir"/../stacks/setup.sh
