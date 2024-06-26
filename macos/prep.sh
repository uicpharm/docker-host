#!/bin/bash

SCRIPT_TITLE="Install Homebrew 🍺"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
# shellcheck disable=SC2016
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "$HOME/.zprofile"
eval "$(/opt/homebrew/bin/brew shellenv)"

echo Done installing Homebrew! 🍺
