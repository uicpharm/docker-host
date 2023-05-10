#!/bin/bash

scr_dir="${0%/*}"

for stackinstaller in "$scr_dir"/*-install.sh; do
   stackname="$(basename "$stackinstaller" | sed -e "s/-install.sh//")"
   echo -n "Do you want to install $stackname? [Y/n]: "
   read -r yorn
   yorn="${yorn:-Y}"
   [[ "$yorn" =~ [Yy] ]] && $stackinstaller
done
