#!/bin/bash

norm=$(tput sgr0)
ul=$(tput smul)
rmul=$(tput rmul)
bold=$(tput bold)
red=$(tput setaf 1)

SCRIPT_TITLE="Install GitHub Actions runner"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$bold\n#\n# $SCRIPT_TITLE \n#\n$norm"
sleep 2

# Settings
user=github
runnerdir=runner
org="uicpharm"
runner_version="2.321.0"

# Detect OS/architecture
[ "$(uname)" = 'Linux' ] && os='linux'
[ "$(uname)" = 'Darwin' ] && os='osx'
arch=$(uname -m | sed -e 's/aarch/arm/' -e 's/x86_/x/')

# If we can't find the right OS and arch, abort.
if [ -z "$os" ] || [ -z "$arch" ]; then
   echo 'Could not determine the OS or architecture!'
   exit 1
fi

# Requires curl and jq utilities
if [[ -z $(which curl) ]] || [[ -z $(which jq) ]]; then
   echo "${red}${bold}This command requires ${ul}curl$rmul and ${ul}jq$rmul to work.$norm" >&2
   exit 1
fi

# Compare our version to latest version on GitHub. If they're different, see if
# the user would like to use the latest version instead.
latest_runner_version=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/[a-z]//Ig')
if [[ -n $latest_runner_version && $latest_runner_version != "$runner_version" ]]; then
   echo "We've tested GitHub Actions Runner ${bold}${ul}v$runner_version$norm, but now ${bold}${ul}v$latest_runner_version$norm is available."
   read -r -p "Do you want to use the newer version? [Y/n] " yorn
   yorn=${yorn:-y} # Enter defaults to 'y'
   yorn=$(echo "${yorn:0:1}" | tr '[:upper:]' '[:lower:]') # Take first character only, and convert to lowercase
   [[ $yorn == y ]] && runner_version=$latest_runner_version
fi

# Calculate installer filename based on system
installer_filename="actions-runner-$os-$arch-$runner_version.tar.gz"
echo "Using GitHub Actions Runner installer $ul$installer_filename$norm."

# Create the user and give permissions
adduser $user
echo "Set a password for the \"$user\" user"
passwd $user
usermod -aG docker $user 2>/dev/null

# Add sudo rules for the new user. Instead of edit the main sudoers file, we create a
# separate file in /etc/sudoers.d for just this user's rules.
mkdir -p /etc/sudoers.d
sudoers_file=/etc/sudoers.d/$user
rm -f "$sudoers_file"
for cmd in docker git deploy; do
   bin=$(which "$cmd")
   echo "$user ALL=(ALL) NOPASSWD: $bin" | tee -a "$sudoers_file" > /dev/null
done
chmod 0440 "$sudoers_file"
# It's important to check the file so that sudo isn't messed up on the system
if visudo -cf "$sudoers_file"; then
   echo "Sudo rules added successfully for $user."
else
   echo "${bold}${red}Failed to add sudo rules. Please fix the issue.$norm" >&2
   rm -f "$sudoers_file"
fi

# Actual installation steps of the runner (ran as the new user)
actionsdir="$(eval echo "~$user")/$runnerdir"
echo "Removing the existing '$actionsdir' directory, if it exists, to start fresh."
runuser -l $user -c "\
   rm -Rf $actionsdir && \
   mkdir -p $actionsdir && \
   cd $actionsdir && \
   curl -O -L https://github.com/actions/runner/releases/download/v$runner_version/$installer_filename && \
   tar xzf ./$installer_filename \
"
sh -c "$actionsdir/bin/installdependencies.sh"

# Configuration (also ran as the new user)
echo "Please go to this link and find the token in the 'Configure' section:"
echo "https://github.com/organizations/$org/settings/actions/runners/new?arch=$arch&os=$os"
read -r -p "Type just the token: " tok
h=${HOSTNAME,,}
runuser -l $user -c "cd $actionsdir && ./config.sh --url https://github.com/$org --labels '${h%%.*},$h' --token $tok"

# Now as the power user who is running the install script, set up the service
(
   cd "$actionsdir" && \
   ./svc.sh install "$user" && \
   # For SELinux systems, make sure runsvc.sh has the correct SELinux context
   if which getenforce > /dev/null && getenforce > /dev/null; then
      echo "Setting the SELinux context for ${ul}runsvc.sh$rmul."
      chcon -t bin_t -v "$actionsdir/runsvc.sh"
   fi && \
   ./svc.sh start && \
   echo Done installing GitHub Actions runner!
)
