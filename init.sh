#!/bin/bash

# Params
branch=main
[[ $1 != -* && -n $1 ]] && branch=$1

# Asks a yes/no question and returns 0 for 'yes' and 1 for 'no'. If the user does not
# provide a response, it uses the default value.
function yorn() {
   local question=$1
   local default=${2:-y}
   while true; do
      echo -n "$question " >&2
      [[ $default =~ [Yy] ]] && echo -n "[Y/n]: " >&2 || echo -n "[y/N]: " >&2
      read -r response
      [[ -z $response ]] && response=$default
      response=$(echo "${response:0:1}" | tr '[:upper:]' '[:lower:]')
      if [[ $response == y ]]; then
         return 0
      elif [[ $response == n ]]; then
         return 1
      else
         echo "Please answer 'y' or 'n'." >&2
      fi
   done
}

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
   question="Create the directory $BASEDIR, right?"
   [[ -d $BASEDIR ]] && question="Install files in existing directory $BASEDIR, right?"
   yorn "$question" y && break
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
   if yorn 'We have to install git or we cannot proceed. Is that okay?' 'y'; then
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
[ ! -d "$REPO_DIR" ] && git clone -b "$branch" "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR" || exit 1

PS3="Select your Linux flavor: "
# shellcheck disable=SC2010
select flavor in $(ls -d -- */ | grep -v exp | grep -v secrets | grep -v shared | grep -v stacks | grep -v node_modules | cut -d'/' -f1); do
   break
done

if [ -z "$flavor" ]; then
   echo "'$REPLY' is not a choice. Aborting."
else
   cd "$flavor" || exit 1
   ./setup.sh
fi
