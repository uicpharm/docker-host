#!/bin/bash

SCRIPT_TITLE="Authenticate to $(tput smul)ghcr.io$(tput rmul)"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

echo "Please provide credentials to $(tput smul)ghcr.io/uicpharm$(tput sgr0) for future projects to download images."
PROCEED=false
while ! $PROCEED; do
   if docker login ghcr.io/uicpharm; then
      PROCEED=true
   else
      echo -n 'Did you want to try again? [Y/n]: '
      read -r yorn
      [[ "${yorn:-Y}" =~ [Nn] ]] && PROCEED=true && echo Skipping Docker authentication.
   fi
done

echo If you need to change the credentials later, you can run: "$(tput bold)docker login ghcr.io/uicpharm$(tput sgr0)"
echo Done authenticating!
