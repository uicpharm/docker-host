#!/bin/bash

scr_dir="${0%/*}"

# Get all scripts, and compile their titles into an array of choices
# shellcheck disable=SC2207
scripts=( $(ls "$scr_dir"/?-*.sh 2>/dev/null) )
if [ ${#scripts[@]} -eq 0 ]; then echo "$(tput setaf 1)There are no steps defined for this setup script. Sorry!$(tput sgr0)"; exit 1; fi
for file in "${scripts[@]}"; do choices+=( "$($file --title)" ); done

PS3='How far in the installation process do you want to go? '
select choice in "${choices[@]}"; do
   if [ -z "$choice" ]; then echo 'That is not a valid choice.'; else break; fi
done

for (( i=0; i<REPLY; i++ )); do
   script="${scripts[$i]}"
   clear
   $script
   sleep 5
done
