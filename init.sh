#!/bin/bash

bold=$(tput bold)
norm=$(tput sgr0)
echo "
Please select a base directory where we will install things. We will put a
directory called 'docker-host' ${bold}inside${norm} that directory. Use the base directory to
store other app configurations and data so it's conveniently all in one place.
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

# Determine if git needs to be installed. On macOS, we check if developer tools are installed. On
# all other platforms, we just check if `git --version` is successful.
NEED_GIT=true
if [ "$(uname)" = "Darwin" ]; then
   xcode-select --print-path &> /dev/null && NEED_GIT=false
else
   git --version &> /dev/null && NEED_GIT=false
fi

if $NEED_GIT; then
   echo -n 'We have to install git or we cannot proceed. Is that okay? [Y/n]: '
   read -r yorn
   yorn="${yorn:-Y}"
   if [[ "$yorn" =~ [Yy] ]]; then
      # Install git with apt or yum
      if [ -n "$(command -v dnf)" ]; then
         dnf install -y git || exit 1
      elif [ -n "$(command -v yum)" ]; then
         yum install -y git || exit 1
      elif [ -n "$(command -v xcode-select)" ]; then
         xcode-select --install
         # Wait until the interactive install is done
         echo -n "Follow the GUI installer. Waiting for installation to finish"
         until xcode-select --print-path &> /dev/null; do echo -n '.'; sleep 5; done
         echo '\nGreat, developer tools are installed!'
      elif [ -n "$(command -v apt)"  ]; then
         apt update -y && apt install -y git || exit 1
      else
         echo "Could not determine application repository. Supports apt, dnf, yum, and xcode-select."
         exit 1
      fi
   else
      echo 'Ok, we must abort then.'
      exit
   fi
fi

# Clone the project if the dir doesn't exist
REPO_DIR="$BASEDIR/docker-host"
REPO_URL="https://github.com/uicpharm/docker-host.git"
mkdir -p "$BASEDIR" || exit 1
[ ! -d "$REPO_DIR" ] && git clone "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR" || exit 1

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
