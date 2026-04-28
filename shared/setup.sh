#!/bin/bash

scr_dir="${0%/*}"

# Multi-select menu in pure bash
multi_select_menu() {
   local cursor=0
   local key
   local options=("$@")
   local selected=()

   # Find the length of the longest option, and set selections to false
   local maxlen=0
   for ((i=0; i<${#options[@]}; i++)); do
      (( ${#options[i]} > maxlen )) && maxlen=${#options[i]}
      selected[i]=false
   done
   local padlen=$((maxlen + 7))

   tput sc >&2 && tput civis >&2
   while true; do
      tput rc >&2
      for ((i=0; i<${#options[@]}; i++)); do
         tput el >&2
         box=○ && ${selected[i]} && box=◉
         # shellcheck disable=SC2059
         printf -v line "%-*s" "$padlen" " $box ${options[i]}"
         ((cursor==i)) && tput setab 4 >&2 && tput setaf 7 >&2
         echo "$line" >&2
         tput sgr0 >&2
      done
      tput dim >&2
      echo "Use ↑/↓ to move, SPACE to select/deselect, ENTER to confirm." >&2
      tput sgr0 >&2

      # Read key
      IFS= read -rsn1 key
      if [[ $key == $'\x1b' ]]; then
         read -rsn2 key
         if [[ $key == "[A" ]]; then
            ((cursor--))
            ((cursor<0)) && cursor=$((${#options[@]}-1))
         elif [[ $key == "[B" ]]; then
            ((cursor++))
            ((cursor>=${#options[@]})) && cursor=0
         fi
      elif [[ $key == " " ]]; then
         if ${selected[cursor]}; then selected[cursor]=false; else selected[cursor]=true; fi
      elif [[ $key == "" ]]; then
         break
      fi
   done

   # Show cursor
   tput cnorm >&2

   # Collect selected items
   local result=()
   for ((i=0; i<${#selected[@]}; i++)); do
      ${selected[i]} && result+=("$i")
   done
   echo "${result[@]}"
}

# Get all scripts, and compile their titles into an array of choices
# shellcheck disable=SC2207
scripts=( $(ls "$scr_dir"/?-*.sh 2>/dev/null) )
if [ ${#scripts[@]} -eq 0 ]; then echo "$(tput setaf 1)There are no steps defined for this setup script. Sorry!$(tput sgr0)"; exit 1; fi
for file in "${scripts[@]}"; do choices+=( "$($file --title)" ); done

echo "$(tput bold)Select the modules to install:$(tput sgr0)"
while true; do
   selected_indices=$(multi_select_menu "${choices[@]}")
   [[ -n $selected_indices ]] && break
   tput setaf 1 && echo 'Please select at least one module.' && tput sgr0
done

read -ra indices_array <<< "$selected_indices"
for i in "${indices_array[@]}"; do
   script="${scripts[$i]}"
   clear
   $script
   sleep 5
done
