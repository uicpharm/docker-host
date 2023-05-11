#!/bin/bash

bold=$(tput bold)
norm=$(tput sgr0)
echo "
Please select a base directory where we will install things. We will put a
directory called 'docker-host' ${bold}inside${norm} that directory. Use the base directory to
store other app configurations and data so it's conveniently all in one place.

${bold}Important:${norm} If you are setting up Docker Swarm, this base directory should be a
shared persistent volume with all of the nodes in your cluster.
"
PS3="Select the base directory or type your own: "
select BASEDIR in /data ~; do
   BASEDIR="${BASEDIR:-$REPLY}"
   if [ -d "$BASEDIR" ]; then
      echo -n "Install files in existing directory $BASEDIR, right? [Y/n]: "
   else
      echo -n "Create the directory $BASEDIR, right? [Y/n]: "
   fi
   read -r yorn
   [[ "${yorn:-Y}" =~ [Yy] ]] && break
done

# If git cmd is not installed, ask to install it
if [ -z "$(command -v git)" ]; then
   echo -n 'We have to install git or we cannot proceed. Is that okay? [Y/n]: '
   read -r yorn
   yorn="${yorn:-Y}"
   if [[ "$yorn" =~ [Yy] ]]; then
      # Install git with apt or yum
      if [ -n "$(command -v yum)" ]; then
         yum install -y git || exit 1
      elif [ -n "$(command -v apt)"  ]; then
         apt update -y && apt install -y git || exit 1
      else
         echo "Could not determine application repository. Supports apt and yum."
         exit 1
      fi
   else
      echo 'Ok, we must abort then.'
      exit
   fi
fi

# Clone the project if the dir doesn't exist
mkdir -p "$BASEDIR" && cd "$BASEDIR" || exit 1
[ ! -d 'docker-host' ] && git clone https://github.com/uicpharm/docker-host.git
cd docker-host || exit 1

PS3="Select your Linux flavor: "
# shellcheck disable=SC2010
select flavor in $(ls -d -- */ | grep -v data | grep -v exp | grep -v stacks | cut -d'/' -f1); do
   break
done

if [ -z "$flavor" ]; then
   echo "'$REPLY' is not a choice. Aborting."
else
   cd "$flavor" || exit 1
   ./setup.sh
fi
