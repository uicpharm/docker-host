#!/bin/bash

scr_dir="${0%/*}"

# Multi-select menu in pure bash
multi_select_menu() {
   local cursor=0
   local key
   local options=("$@")
   local selected=()
   local i maxlen=0 padlen columns paintlen box label rest sequence params highlight_bg highlight_fg
   local escape=$'\033' sgr_pattern=$'\033''\[[0-9;]*m'

   highlight_bg=$(tput setab 4) || return 1
   highlight_fg=$(tput setaf 7) || return 1
   for ((i=0; i<${#options[@]}; i++)); do
      (( ${#options[i]} > maxlen )) && maxlen=${#options[i]}
      selected[i]=false
   done
   padlen=$((maxlen + (maxlen + 4) / 5))

   { tput sc && tput civis; } >&2
   while true; do
      if ! columns=$(tput cols) || [[ ! $columns =~ ^[0-9]+$ ]] || (( 10#$columns < 2 )); then
         echo 'Cannot determine terminal width for the selection menu.' >&2
         tput cnorm >&2
         return 1
      fi
      columns=$((10#$columns))
      paintlen=$padlen
      (( paintlen >= columns )) && paintlen=$((columns - 1))
      tput rc >&2
      for ((i=0; i<${#options[@]}; i++)); do
         tput el >&2
         box=○ && ${selected[i]} && box=◉
         label=${options[i]}
         if ((cursor==i)); then
            rest=$label
            label=''
            while [[ $rest =~ $sgr_pattern ]]; do
               sequence=${BASH_REMATCH[0]}
               label+=${rest%%"$sequence"*}$sequence$highlight_bg
               params=${sequence#"${escape}["}
               params=${params%m}
               if [[ -z $params || ";$params;" == *';0;'* ]] &&
                  [[ ! ";$params;" =~ \;(3[0-8]|9[0-7])\; ]]; then
                  label+=$highlight_fg
               fi
               rest=${rest#*"$sequence"}
            done
            label+=$rest
            printf '%s%s%*s\r' "$highlight_bg" "$highlight_fg" "$paintlen" '' >&2
         fi
         printf ' %s %s\n' "$box" "$label" >&2
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

   # Final selection display. Remove highlighting, clear instructions.
   tput rc >&2
   for ((i=0; i<${#options[@]}; i++)); do
      { tput sgr0 && tput el; } >&2
      box=○ && ${selected[i]} && box=◉
      printf ' %s %s\n' "$box" "${options[i]}" >&2
   done
   { tput sgr0 && tput el && tput cnorm && echo; } >&2

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
