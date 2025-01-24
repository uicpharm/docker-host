#!/bin/bash

scr_dir="${0%/*}"

# Collect user groups. We do this in the background right away since a server connected to AD may take
# several seconds to respond with the group list.
real_user=${SUDO_USER:-$(whoami)}
groups_file=$(mktemp)
(id "$real_user" | cut -d'=' -f4 | tr ',' '\n' > "$groups_file") &
groups_pid="$!"

# Create secrets directory
sec_dir=$(realpath "$scr_dir/..")/secrets
mkdir -p "$sec_dir"

# Set strict permissions for the secrets
echo "It is highly recommended that you restrict permissions of the $(tput smul)$(basename "$sec_dir")$(tput rmul) directory."
echo "I can set the group to something your $real_user user also has access to."
read -r -p "Do you want to do this? [Y/n] " yorn
if [[ ${yorn:-y} =~ [Yy] ]]; then
   echo -n "Great! Finding your user groups."
   while ps "$groups_pid" > /dev/null; do echo -n '.'; sleep 1; done
   echo -e '\n'
   while IFS=$'\n' read -r line; do
      group_array+=("$line")
   done <<< "$(<"$groups_file")"
   PS3="Either enter a number or manually type a group name: "
   select group in "${group_array[@]}"; do
      # Accept either the selected group or the manually-entered group
      group=${group:-$REPLY}
      # Don't accept a blank entry
      [[ -n $group ]] && break
   done
   echo "Setting the group of the $(tput smul)$(basename "$sec_dir")$(tput rmul) directory to $(tput smul)$group$(tput rmul)."
   # Groups will look like "123(group_name)", so we get just the number by looking to the left of '('.
   # This will also work with manually entered groups like "group_name" or "123".
   group=$(echo "$group" | cut -d'(' -f1)
   chgrp -R "$group" "$sec_dir"
   chmod -R 770 "$sec_dir"
fi

# Install individual stacks
for stackinstaller in "$scr_dir"/*-install.sh; do
   stackname="$(basename "$stackinstaller" | sed -e "s/-install.sh//")"
   echo -n "Do you want to install $stackname? [Y/n]: "
   read -r yorn
   yorn="${yorn:-Y}"
   [[ "$yorn" =~ [Yy] ]] && $stackinstaller
done
