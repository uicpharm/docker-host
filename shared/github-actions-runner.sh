#!/bin/bash

SCRIPT_TITLE="Install GitHub Actions runner"
if [[ " $* " == *" --title "* ]]; then echo "$SCRIPT_TITLE"; exit 0; fi
echo -e "$(tput bold)\n#\n# $SCRIPT_TITLE \n#\n$(tput sgr0)"
sleep 2

# Settings
user=github
runnerdir=runner
org="uicpharm"
ver="2.321.0"

# Calculate installer filename based on system
[ "$(uname)" = 'Linux' ] && os='linux'
[ "$(uname)" = 'Darwin' ] && os='osx'
arch=$(uname -m | sed -e 's/aarch/arm/' -e 's/x86_/x/')
installer_filename="actions-runner-$os-$arch-$ver.tar.gz"

# If we can't find the right OS and arch, abort.
if [ -z "$os" ] || [ -z "$arch" ]; then
   echo 'Could not determine the OS or architecture!'
   exit 1
fi

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
   echo "$(tput bold)$(tput setaf 1)Failed to add sudo rules. Please fix the issue.$(tput sgr0)" >&2
   rm -f "$sudoers_file"
fi

# Actual installation steps of the runner (ran as the new user)
actionsdir="$(eval echo "~$user")/$runnerdir"
echo "Removing the existing '$actionsdir' directory, if it exists, to start fresh."
runuser -l $user -c "\
   rm -Rf $actionsdir && \
   mkdir -p $actionsdir && \
   cd $actionsdir && \
   curl -O -L https://github.com/actions/runner/releases/download/v$ver/$installer_filename && \
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
   if which chcon &> /dev/null; then
      echo "Setting the SELinux context for $(tput smul)runsvc.sh$(tput rmul)."
      chcon -t bin_t -v "$actionsdir/runsvc.sh"
   fi && \
   ./svc.sh start && \
   echo Done installing GitHub Actions runner!
)
